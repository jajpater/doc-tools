-- Preserve Markdown HTML comments in Typst without interpreting their contents.
local style = os.getenv("MD_TO_TYP_COMMENT_STYLE") or "line"

local function convert_comment(el, constructor, inline)
  if FORMAT ~= "typst" or el.format ~= "html" then
    return nil
  end

  local body = el.text:match("^<!%-%-(.-)%-%->$")
  if body == nil then
    return nil
  end

  if style == "none" then
    return {}
  end

  if style == "line" then
    local comment = "//" .. body:gsub("\n", "\n//") .. "\n"
    if inline then
      -- A bare line comment adds whitespace between adjacent words. A code
      -- block evaluates to nothing and keeps its newline out of the paragraph.
      comment = "#{" .. comment .. "}"
    end
    return constructor("typst", comment)
  end

  -- Typst nests block comments. Neutralize delimiters in the comment text so
  -- they cannot close the comment early or leave an unterminated nested one.
  body = body:gsub("/%*", "/ *"):gsub("%*/", "* /")
  if body:sub(-1) == "/" then
    body = body .. " "
  end
  return constructor("typst", "/*" .. body .. "*/")
end

function RawBlock(el)
  return convert_comment(el, pandoc.RawBlock)
end

function RawInline(el)
  return convert_comment(el, pandoc.RawInline, true)
end
