--[[
  @author Digital.
  @url https://github.com/dig/onset-camera-library
]]

local CameraTimer = 0
local CameraTick = 10

local CameraCurrentIndex = 1
local CameraCurrentStep = 0

local function Path_OnCameraTick(path, length, data, steps)
  if data[CameraCurrentIndex] == nil then return Base_StopCamera() end
  local _data = data[CameraCurrentIndex]

  local x, y, z = GetCameraLocation(false)
  local rx, ry, rz = GetCameraRotation()

  local nx, ny, nz = x + _data.sx, y + _data.sy, z + _data.sz
  local nrx, nry, nrz = rx + _data.srx, ry + _data.sry, rz + _data.srz

  SetCameraLocation(nx, ny, nz, true)
  SetCameraRotation(nrx, nry, nrz, true)
  CameraCurrentStep = CameraCurrentStep + 1

  if (CameraCurrentStep >= steps) then
    if CameraCurrentIndex >= (#path - 1) then
      Base_StopCamera()
    else
      CameraCurrentStep = 0
      CameraCurrentIndex = CameraCurrentIndex + 1
    end
  end
end

local function Path_StartCamera(path, length)
  if (path == nil or length == nil or CameraState ~= CAMERA_DISABLED) then return end

  -- Validation of path
  local _isValidPaths = true
  for _, v in ipairs(path) do
    if #v ~= 6 then
      _isValidPaths = false
    end
  end
  if not _isValidPaths then return print('Camera: Paths are not defined correctly.') end

  CameraCurrentIndex = 1
  CameraCurrentStep = 0
  
  -- Calculate path steps
  local _data = {}
  local steps = (length / (#path - 1)) / CameraTick

  for i, current in ipairs(path) do
    if path[i + 1] ~= nil then
      local next = path[i + 1]

      local cx, cy, cz, crx, cry, crz = current[1], current[2], current[3], current[4], current[5], current[6]  
      local nx, ny, nz, nrx, nry, nrz = next[1], next[2], next[3], next[4], next[5], next[6]

      local srx = (nrx - crx) / steps
      local sry = (nry - cry) / steps
      local srz = (nrz - crz) / steps

      if nrx < 180 and crx > 180 then
        srx = ((360 - crx) / steps) + (nrx / steps)
      elseif crx < 180 and nrx > 180 then
        srx = (crx / steps) + ((360 - nrx) / steps)
      end

      if sry <= 180 then
        if cry < nry then
          sry = sry
        else
          sry = -sry
        end
      elseif cry < nry then
        sry = -(360 - sry)
      else
        sry = 360 - sry
      end

      _data[i] = {
        sx = (nx - cx) / steps,
        sy = (ny - cy) / steps,
        sz = (nz - cz) / steps,

        srx = srx,
        sry = sry,
        srz = srz
      }
    end
  end

  if #_data <= 0 then return print('Camera: Unable to calculate path steps.') end

  -- Set starting position
  local x, y, z, rx, ry, rz = path[1][1], path[1][2], path[1][3], path[1][4], path[1][5], path[1][6] 
  SetCameraLocation(x, y, z, true)
  SetCameraRotation(rx, ry, rz, true)

  CameraTimer = CreateTimer(Path_OnCameraTick, CameraTick, path, length, _data, steps)
  CameraState = CAMERA_ENABLED

  CallEvent('CameraStart', CAMERA_PATH)
end
AddFunctionExport('StartCameraPath', Path_StartCamera)

local function Path_OnStopCamera()
  if (CameraState == CAMERA_ENABLED and CameraTimer ~= 0) then
    DestroyTimer(CameraTimer)
    CallEvent('CameraStop', CAMERA_PATH)
  end
end
AddEvent('_OnStopCamera', Path_OnStopCamera)