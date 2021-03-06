-- cwdの値を元にrequireをするようにした

local L = {}
L.require = require
L.cwd = ""

local cache = {}

require = function(path)
  local prevCwd = L.cwd

  local normalizedPath = path
  -- 先頭が"."ではない時、pathの先頭に"."を付与
  if string.find(path, "^[^%.]") then
    normalizedPath = "." .. path
  end
  
  -- ...で始まるときは絶対パス
  if string.find(path, "^[%.][%.][%.]") and not string.find(path, "^[%.][%.][%.][%.]")  then
    normalizedPath = string.sub(normalizedPath, 4)
  else
    -- path を正規化
    normalizedPath = L.normalize(L.cwd .. normalizedPath)
    

    -- 本来のrequireを実行
    -- 標準ライブラリの場合、先頭に"."がついているとエラーになるので取り除く

    if string.find(normalizedPath, "^[%.]") then
      normalizedPath = string.sub(normalizedPath, 2)
    end
  end

  -- cwdを変更
  L.cwd = L.getDirName(normalizedPath)

  if cache[normalizedPath] then
    L.cwd = prevCwd
    return cache[normalizedPath]
  end
  local result, mod = pcall(L.require, normalizedPath)
  if not result then
    result, mod = pcall(L.require, path)
    if not result then
      local errorMessage = mod
      print("require failed :" .. normalizedPath)
      print(errorMessage)
      assert(result, "origin require failed :" .. path)
    end
  end

  -- require が終わったらcwdをrequire前の値に戻す
  L.cwd = prevCwd

  cache[normalizedPath] = mod

  return mod
end

do
  local results

  -- ファイルパスの正規化を行う
  function L.normalize(path)
    results = {}
    local arr = L.split(path, "%.%.")
    for i, v in ipairs(arr) do
      L._normalize(v)
    end
    return table.concat(results, ".")
  end

  -- 補助関数
  function L._normalize(path)
    local arr = L.split(path, "%.")
    table.remove(results)
    if path == '' then
      return
    end
    for i, v in ipairs(arr) do
      table.insert(results, v)
    end
  end
end

-- フルパスからディレクトリ名のみを抽出
function L.getDirName(path)
--   if string.find(path, "^[%.][%.][%.]") then
--     path = string.sub(path, 4)
--   end
  path = string.reverse(path)
  local i, j = string.find(path, "%.")
  if not j then
    return ""
  end
  path = string.sub(path, j + 1)

  return string.reverse(path)
end

-- フルパスからファイル名のみを抽出
function L.getBaseName(path)
  path = string.reverse(path)
  local i, j = string.find(path, "%.")
  path = string.sub(path, 1, j)

  return string.reverse(path)
end

-- utilsにも同じものがあるが、requireできないためコピペ
function L.split(str, delim)
  if string.find(str, delim) == nil then
      return { str }
  end

  local result = {}
  local pat = "(.-)" .. delim .. "()"
  local lastPos
  for part, pos in string.gfind(str, pat) do
      table.insert(result, part)
      lastPos = pos
  end
  table.insert(result, string.sub(str, lastPos))
  return result
end


-- 懸念事項
-- キャッシュ

