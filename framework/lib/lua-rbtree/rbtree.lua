local rbtree = require "rbtree"

local mt = {}
mt.__index = mt

function mt:insert(score, member)
    if self.rbt then
        local old = self.tbl[member]
        if old then
            if old == score then
                return
            end
            self.rbt:delete(old, member)
        end

        self.rbt:insert(score, member)
        self.tbl[member] = score
    else
        print("rbtree insert error")
    end
end

function mt:rem(member)
    local score = self.tbl[member]
    if score then
        self.rbt:delete(score, member)
        self.tbl[member] = nil
    end
end

function mt:count()
    return self.rbt:get_count()
end

function mt:_reverse_rank(r)
    return self.rbt:get_count() - r + 1
end

function mt:limit(count, delete_handler)
    local total = self.rbt:get_count()
    if total <= count then
        return 0
    end

    local delete_function = function(member)
        self.tbl[member] = nil
        if delete_handler then
            delete_handler(member)
        end
    end

    return self.rbt:delete_by_rank(count+1, total, delete_function)
end

function mt:rev_limit(count, delete_handler)
    local total = self.rbt:get_count()
    if total <= count then
        return 0
    end
    local from = self:_reverse_rank(count+1)
    local to   = self:_reverse_rank(total)

    local delete_function = function(member)
        self.tbl[member] = nil
        if delete_handler then
            delete_handler(member)
        end
    end

    return self.rbt:delete_by_rank(from, to, delete_function)
end

function mt:rev_range(r1, r2)
    r1 = self:_reverse_rank(r1)
    r2 = self:_reverse_rank(r2)
    return self:range(r1, r2)
end

function mt:range(r1, r2)
    if r1 < 1 then
        r1 = 1
    end

    if r2 < 1 then
        r2 = 1
    end
    return self.rbt:get_rank_range(r1, r2)
end

function mt:rev_rank(member)
    local r = self:rank(member)
    if r then
        return self:_reverse_rank(r)
    end
    return r
end

function mt:rank(member)
    local score = self.tbl[member]
    if not score then
        return nil
    end
    return self.rbt:get_rank(score, member)
end

function mt:range_by_score(s1, s2)
    return self.rbt:get_score_range(s1, s2)
end

function mt:score(member)
    return self.tbl[member]
end

function mt:member_by_rank(r)
    return self.rbt:get_member_by_rank(r)
end

function mt:member_by_rev_rank(r)
    r = self:_reverse_rank(r)
    if r > 0 then
        return self.rbt:get_member_by_rank(r)
    end
end

function mt:dump()
    self.rbt:dump()
end

local M = {}

function M.new()
    local obj = {}
    obj.rbt = rbtree()
    obj.tbl = {}
    return setmetatable(obj, mt)
end

return M
