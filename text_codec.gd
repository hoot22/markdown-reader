extends RefCounted

## 文本编码探测与解码。
## Godot 只内置 UTF-8/UTF-16/UTF-32，GBK 需要自带码表：
## assets/encoding/gbk_table.bin 覆盖首字节 0x81-0xFE、尾字节 0x40-0xFE（去掉 0x7F）
## 共 23940 个位置，每项小端 uint16，0 表示该位置未定义。

const TABLE_PATH: String = "res://assets/encoding/gbk_table.bin"
const TABLE_ENTRIES: int = 23940
const TRAIL_COUNT: int = 190
const REPLACEMENT: int = 0xFFFD

static var _table: PackedByteArray = PackedByteArray()

## 按 BOM、UTF-8 合法性、GBK 的顺序解码字节流。
static func decode(data: PackedByteArray) -> String:
	if data.is_empty():
		return ""
	if data.size() >= 3 and data[0] == 0xEF and data[1] == 0xBB and data[2] == 0xBF:
		return data.slice(3).get_string_from_utf8()
	if data.size() >= 2 and data[0] == 0xFF and data[1] == 0xFE:
		return data.slice(2).get_string_from_utf16()
	if data.size() >= 2 and data[0] == 0xFE and data[1] == 0xFF:
		return _swap_bytes16(data.slice(2)).get_string_from_utf16()
	if _is_valid_utf8(data):
		return data.get_string_from_utf8()
	return _decode_gbk(data)


## 逐字节校验，不依赖引擎“非法输入返回空串”的隐含行为。
static func _is_valid_utf8(data: PackedByteArray) -> bool:
	var size: int = data.size()
	var i: int = 0
	while i < size:
		var lead: int = data[i]
		if lead < 0x80:
			i += 1
			continue
		var extra: int = 0
		if lead >= 0xC2 and lead <= 0xDF:
			extra = 1
		elif lead >= 0xE0 and lead <= 0xEF:
			extra = 2
		elif lead >= 0xF0 and lead <= 0xF4:
			extra = 3
		else:
			return false
		if i + extra >= size:
			return false
		var code: int = lead & (0x3F >> extra)
		var k: int = 1
		while k <= extra:
			var cont: int = data[i + k]
			if cont < 0x80 or cont > 0xBF:
				return false
			code = (code << 6) | (cont & 0x3F)
			k += 1
		# 拒绝过长编码与 UTF-16 代理区
		if extra == 1 and code < 0x80:
			return false
		if extra == 2 and code < 0x800:
			return false
		if extra == 3 and code < 0x10000:
			return false
		if code >= 0xD800 and code <= 0xDFFF:
			return false
		if code > 0x10FFFF:
			return false
		i += extra + 1
	return true


## UTF-16BE 转字节序，逐对交换而非整体反转。
static func _swap_bytes16(data: PackedByteArray) -> PackedByteArray:
	var out: PackedByteArray = data.duplicate()
	var i: int = 0
	while i + 1 < out.size():
		var tmp: int = out[i]
		out[i] = out[i + 1]
		out[i + 1] = tmp
		i += 2
	return out


static func _decode_gbk(data: PackedByteArray) -> String:
	if not _ensure_table():
		# 码表缺失时退回 UTF-8，至少 ASCII 部分可读
		return data.get_string_from_utf8()
	var out: PackedByteArray = PackedByteArray()
	var size: int = data.size()
	var i: int = 0
	while i < size:
		var lead: int = data[i]
		if lead < 0x80:
			out.append(lead)
			i += 1
			continue
		# 0x80 在部分实现中映射到欧元符号
		if lead == 0x80:
			_append_utf8(out, 0x20AC)
			i += 1
			continue
		# 0xFF 非法，或尾字节缺失
		if lead > 0xFE or i + 1 >= size:
			_append_utf8(out, REPLACEMENT)
			i += 1
			continue
		var trail: int = data[i + 1]
		if trail < 0x40 or trail == 0x7F or trail > 0xFE:
			_append_utf8(out, REPLACEMENT)
			i += 1
			continue
		var column: int = trail - 0x40
		if trail > 0x7F:
			column -= 1
		var index: int = (lead - 0x81) * TRAIL_COUNT + column
		if index < 0 or index >= TABLE_ENTRIES:
			_append_utf8(out, REPLACEMENT)
			i += 1
			continue
		var codepoint: int = _table[index * 2] | (_table[index * 2 + 1] << 8)
		if codepoint == 0:
			_append_utf8(out, REPLACEMENT)
			i += 2
			continue
		_append_utf8(out, codepoint)
		i += 2
	return out.get_string_from_utf8()


static func _ensure_table() -> bool:
	if not _table.is_empty():
		return true
	if not FileAccess.file_exists(TABLE_PATH):
		return false
	var file: FileAccess = FileAccess.open(TABLE_PATH, FileAccess.READ)
	if file == null:
		return false
	_table = file.get_buffer(TABLE_ENTRIES * 2)
	file.close()
	return _table.size() == TABLE_ENTRIES * 2


static func _append_utf8(out: PackedByteArray, codepoint: int) -> void:
	if codepoint < 0x80:
		out.append(codepoint)
	elif codepoint < 0x800:
		out.append(0xC0 | (codepoint >> 6))
		out.append(0x80 | (codepoint & 0x3F))
	elif codepoint < 0x10000:
		out.append(0xE0 | (codepoint >> 12))
		out.append(0x80 | ((codepoint >> 6) & 0x3F))
		out.append(0x80 | (codepoint & 0x3F))
	else:
		out.append(0xF0 | (codepoint >> 18))
		out.append(0x80 | ((codepoint >> 12) & 0x3F))
		out.append(0x80 | ((codepoint >> 6) & 0x3F))
		out.append(0x80 | (codepoint & 0x3F))
