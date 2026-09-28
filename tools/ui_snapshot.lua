-- Serialize the offline UI fixture, never a live-client screenshot.
return function(frames,path)
    local ids={}; for i,frame in ipairs(frames) do ids[frame]=i end
    local function encode(value)
        local t=type(value)
        if t=="nil" then return "null" end
        if t=="boolean" or t=="number" then return tostring(value) end
        if t=="string" then return '"'..value:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"' end
        if t=="table" then
            if ids[value] then return '{"ref":'..ids[value]..'}' end
            local out={}
            for _,v in ipairs(value) do out[#out+1]=encode(v) end
            return '['..table.concat(out,',')..']'
        end
        error("Unsupported fixture value: "..t)
    end
    local rows={}
    for i,frame in ipairs(frames) do
        local fields={'"id":'..i}
        for _,key in ipairs({"kind","parent","shown","width","height","fontSize","justify","textColor","color","tint","texture","text","points","allPoints","texCoord","strata"}) do
            if frame[key]~=nil then fields[#fields+1]='"'..key..'":'..encode(frame[key]) end
        end
        rows[#rows+1]='{'..table.concat(fields,',')..'}'
    end
    local file=assert(io.open(path,"wb")); file:write('['..table.concat(rows,',')..']'); file:close()
end
