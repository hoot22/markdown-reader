extends RefCounted
## 把 Markdown / HTML 里的相对图片路径补成绝对路径

## 图片格式列表
const IMAGE_EXTENSIONS: PackedStringArray = ["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "ico", "avif", "tga"]

static var _inline_image_regex: RegEx
static var _html_image_regex: RegEx
static var _reference_regex: RegEx


## 返回改写后的文本；base_dir 不是可用的本地绝对目录时原样返回
static func rewrite(text: String, base_dir: String) -> String:
	var root: String = _normalize_base_dir(base_dir)
	if root.is_empty() or text.is_empty():
		return text
	_ensure_regex()
	var lines: PackedStringArray = text.split("\n")
	var fence: String = ""
	for index: int in range(lines.size()):
		var line: String = lines[index]
		var trimmed: String = line.strip_edges()
		if fence.is_empty():
			# 围栏代码块内部的图片语法属于示例代码，不改写
			if trimmed.begins_with("```") or trimmed.begins_with("~~~"):
				fence = trimmed.substr(0, 3)
				continue
			lines[index] = _rewrite_line(line, root)
		elif trimmed.begins_with(fence):
			fence = ""
	return "\n".join(lines)


static func _normalize_base_dir(base_dir: String) -> String:
	var dir: String = base_dir.replace("\\", "/").strip_edges()
	while dir.ends_with("/"):
		dir = dir.trim_suffix("/")
	if dir.is_empty():
		return ""
	# res:// 与 user://由引擎解析，不在这里处理
	if dir.begins_with("res://") or dir.begins_with("user://"):
		return ""
	if not dir.is_absolute_path():
		return ""
	return dir


static func _ensure_regex() -> void:
	if _inline_image_regex != null:
		return
	_inline_image_regex = RegEx.new()
	_inline_image_regex.compile("!\\[[^\\]]*\\]\\(\\s*([^()\\s<>]+)([^)]*)\\)")
	_html_image_regex = RegEx.new()
	_html_image_regex.compile("(?i)<img\\b[^>]*?\\bsrc\\s*=\\s*([\"'])([^\"']+)\\1")
	_reference_regex = RegEx.new()
	_reference_regex.compile("^\\s{0,3}\\[[^\\]]+\\]:\\s*(\\S+)")


## 逐字符扫描，只处理反引号之外的片段，行内代码保持原样
static func _rewrite_line(line: String, root: String) -> String:
	var result: String = ""
	var buffer: String = ""
	var in_code: bool = false
	for index: int in range(line.length()):
		var ch: String = line[index]
		if ch == "`":
			result += buffer if in_code else _rewrite_segment(buffer, root)
			buffer = ""
			result += "`"
			in_code = not in_code
		else:
			buffer += ch
	result += buffer if in_code else _rewrite_segment(buffer, root)
	return result


static func _rewrite_segment(segment: String, root: String) -> String:
	var result: String = segment
	result = _replace_targets(result, _inline_image_regex, 1, root, false)
	result = _replace_targets(result, _html_image_regex, 2, root, false)
	# 引用式定义同时服务普通链接，只在扩展名明确是图片时才改写
	result = _replace_targets(result, _reference_regex, 1, root, true)
	return result


static func _replace_targets(segment: String, regex: RegEx, group: int, root: String, require_image_ext: bool) -> String:
	var matches: Array[RegExMatch] = regex.search_all(segment)
	if matches.is_empty():
		return segment
	var result: String = ""
	var cursor: int = 0
	for match_item: RegExMatch in matches:
		var start: int = match_item.get_start(group)
		var end: int = match_item.get_end(group)
		if start < 0 or end < 0:
			continue
		result += segment.substr(cursor, start - cursor)
		result += _resolve_target(match_item.get_string(group), root, require_image_ext)
		cursor = end
	result += segment.substr(cursor)
	return result


static func _resolve_target(target: String, root: String, require_image_ext: bool) -> String:
	var raw: String = target.strip_edges()
	if raw.is_empty() or raw.begins_with("#"):
		return target
	if raw.begins_with("res://") or raw.begins_with("user://") or raw.begins_with("data:"):
		return target
	if raw.contains("://"):
		return target
	# 已经是绝对路径（含盘符）就不动
	if raw.is_absolute_path() or raw.substr(1, 1) == ":":
		return target
	var normalized: String = raw.uri_decode().replace("\\", "/")
	if require_image_ext and not _has_image_extension(normalized):
		return target
	var candidate: String = root.path_join(normalized).simplify_path()
	# 目标文件不存在时保持原样
	if not FileAccess.file_exists(candidate):
		return target
	return candidate


static func _has_image_extension(path: String) -> bool:
	return IMAGE_EXTENSIONS.has(path.get_extension().to_lower())
