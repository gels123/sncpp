--
-- 矩形工具类
--
local rectUtil = {}

-- 根据左上角和右下角坐标生成矩形对象
function rectUtil.rect(ltX, ltY, rbX, rbY)
	local rect = {
		ltX = ltX,
		ltY = ltY,
		rbX = rbX,
		rbY = rbY,
	}
	return rect
end

-- 根据左上角和边长生成矩形
function rectUtil.getRectBySize(ltX, ltY, size)
	local rect = {
		ltX = ltX,
		ltY = ltY,
		rbX = ltX + size - 1,
		rbY = ltY + size - 1,
	}
	return rect
end

-- 是否接壤（包括重叠、覆盖、边缘接壤、顶点接壤）
function rectUtil.isConnect(rectA, rectB)
	return rectUtil.isOverlap(rectUtil.getExpRect(rectA), rectB)
			and (IS_SUPPORT_TERR_ANGLE_CONNECT or not rectUtil.isAngleConnect(rectA, rectB))
end

-- 是否有重叠（包括重叠、覆盖）（比接壤条件少一圈）
function rectUtil.isOverlap(rectA, rectB)
	return not (rectA.rbX < rectB.ltX
			or rectA.ltX > rectB.rbX
			or rectA.rbY < rectB.ltY
			or rectA.ltY > rectB.rbY)
end

-- 是否A覆盖B
function rectUtil.isAcoverB(rectA, rectB)
	return rectA.ltX <= rectB.ltX and rectA.ltY <= rectB.ltY
			and rectA.rbX >= rectB.rbX and rectA.rbY >= rectB.rbY
end

-- 是否边缘接壤
function rectUtil.isEdgeConnect(rectA, rectB)
	return ((rectA.rbX == rectB.ltX - 1 or rectA.ltX == rectB.rbX + 1)
			and not (rectA.rbY < rectB.ltY or rectA.ltY > rectB.rbY))
			or ((rectA.rbY == rectB.ltY - 1 or rectA.ltY == rectB.rbY + 1)
			and not (rectA.rbX < rectB.ltX or rectA.ltX > rectB.rbX))
end

-- 是否顶点接壤
function rectUtil.isAngleConnect(rectA, rectB)
	return (rectA.rbX == rectB.ltX - 1 or rectA.ltX == rectB.rbX + 1)
			and (rectA.rbY == rectB.ltY - 1 or rectA.ltY == rectB.rbY + 1)
end

-- 获取比指定矩形扩展l圈的矩形（负数为缩小）
function rectUtil.getExpRect(rect, l)
	l = l or 1
	local expRect = {
		ltX = rect.ltX - l,
		ltY = rect.ltY - l,
		rbX = rect.rbX + l,
		rbY = rect.rbY + l,
	}
	return expRect
end

-- 获取相交矩形
function rectUtil.getInterRect(rectA, rectB)
	local rect = {
		ltX = math.max(rectA.ltX, rectB.ltX),
		ltY = math.max(rectA.ltY, rectB.ltY),
		rbX = math.min(rectA.rbX, rectB.rbX),
		rbY = math.min(rectA.rbY, rectB.rbY),
	}
	return rect
end

-- 获取最小外接矩形
function rectUtil.getMBR(rectA, rectB)
	local MBR = {
		ltX = math.min(rectA.ltX, rectB.ltX),
		ltY = math.min(rectA.ltY, rectB.ltY),
		rbX = math.max(rectA.rbX, rectB.rbX),
		rbY = math.max(rectA.rbY, rectB.rbY),
	}
	return MBR
end

-- 更新最小外接矩形
function rectUtil.updateMBR(MBR, addRect)
	MBR.ltX = math.min(MBR.ltX or addRect.ltX, addRect.ltX)
	MBR.ltY = math.min(MBR.ltY or addRect.ltY, addRect.ltY)
	MBR.rbX = math.max(MBR.rbX or addRect.rbX, addRect.rbX)
	MBR.rbY = math.max(MBR.rbY or addRect.rbY, addRect.rbY)
end

return rectUtil
