-- Tetris clone using Lua and LOVE
-- By ChatGPT (and me)
--
--          Copyright Joe Coder 2023.
-- Distributed under the Boost Software License, Version 1.0.
--    (See accompanying file LICENSE_1_0.txt or copy at
--          https://www.boost.org/LICENSE_1_0.txt)

-- Constants
local SCREEN_WIDTH = 200
local SCREEN_HEIGHT = 400
local BLOCK_SIZE = 20
local NUM_ROWS = 20
local NUM_COLUMNS = 10
local SHAPE_COLORS = {
  { 1, 0, 0 }, -- Red
  { 0, 1, 0 }, -- Green
  { 0, 0, 1 }, -- Blue
  { 1, 1, 0 }, -- Yellow
  { 1, 0, 1 }, -- Purple
  { 0, 1, 1 }, -- Cyan
  { 1, 1, 1 }, -- White
}
local SHAPES = {
  { { 1, 1, 1, 1 } }, -- I
  { { 1, 1, 0 }, { 0, 1, 1 } }, -- Z
  { { 0, 1, 1 }, { 1, 1, 0 } }, -- S
  { { 1, 1 }, { 1, 1 } }, -- O
  { { 1, 1, 1 }, { 0, 1, 0 } }, -- T
  { { 1, 1, 1 }, { 0, 0, 1 } }, -- J
  { { 1, 1, 1 }, { 1, 0, 0 } }, -- L
}

-- Game variables
local board = {}
local currentShape = {}
local currentShapeColor = {}
local currentShapeRow = 1
local currentShapeColumn = math.floor(NUM_COLUMNS / 2)
local score = 0
local gameOver = false
-- Initialize the timer variables
local timer = 0
local interval = 0.5 -- in seconds
-- Helper functions
local function createShape()
  -- Create a random shape
  local random = math.random(#SHAPES)
  return SHAPES[random], SHAPE_COLORS[random]
end

-- Check if a shape can be placed at a given position on the board
local function canPlaceShape(shape, row, column)
  for shapeRow = 1, #shape do
    for shapeColumn = 1, #shape[1] do
      if shape[shapeRow][shapeColumn] ~= 0 then
        local boardRow = row + shapeRow - 1
        local boardColumn = column + shapeColumn - 1
        -- Check if the shape is out of bounds
        if boardRow < 1 or boardRow > NUM_ROWS or boardColumn < 1 or boardColumn > NUM_COLUMNS then
          return false
        end
        -- Check if the shape overlaps with another block on the board
        if board[boardRow][boardColumn] ~= nil then
          return false
        end
      end
    end
  end
  return true
end

-- Rotate the current shape clockwise
local function rotateShapeClockwise()
  local newShape = {}
  for i = 1, #currentShape[1] do
    newShape[i] = {}
    for j = 1, #currentShape do
      newShape[i][j] = currentShape[#currentShape - j + 1][i]
    end
  end
  if canPlaceShape(newShape, currentShapeRow, currentShapeColumn) then
    currentShape = newShape
  end
end

-- Check if the current shape can be moved left
local function canMoveLeft()
  for row = 1, #currentShape do
    for col = 1, #currentShape[1] do
      if currentShape[row][col] ~= 0 then
        local boardRow = currentShapeRow + row - 1
        local boardCol = currentShapeColumn + col - 2 -- Subtract 1 from column to move left
        if boardCol < 1 or board[boardRow][boardCol] ~= nil then
          return false
        end
      end
    end
  end
  return true
end

-- Check if the current shape can be moved right
local function canMoveRight()
  for row = 1, #currentShape do
    for col = 1, #currentShape[1] do
      if currentShape[row][col] ~= 0 then
        local boardRow = currentShapeRow + row - 1
        local boardCol = currentShapeColumn + col -- Add 1 to column to move right
        if boardCol > NUM_COLUMNS or board[boardRow][boardCol] ~= nil then
          return false
        end
      end
    end
  end
  return true
end

-- Check if the current shape can be moved down
local function canMoveDown()
  -- Iterate through the current shape
  for i = 1, #currentShape do
    for j = 1, #currentShape[i] do
      -- Check if the current block is not an empty block
      if currentShape[i][j] ~= 0 then
        -- Calculate the position of the block on the board
        local row = currentShapeRow + i
        local column = currentShapeColumn + j - 1
        -- Check if the block is at the bottom of the board or if there's another block below it
        if row > NUM_ROWS or board[row][column] then
          return false
        end
      end
    end
  end
  -- If all blocks can move down, return true
  return true
end

local function drawBlock(color, row, column)
  love.graphics.setColor(color)
  love.graphics.rectangle("fill", (column - 1) * BLOCK_SIZE, (row - 1) * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
end

local function drawBoard()
  for row = 1, NUM_ROWS do
    for column = 1, NUM_COLUMNS do
      if board[row][column] then
        drawBlock(board[row][column], row, column)
      end
    end
  end
end

local function placeShape()
  for i = 1, #currentShape do
    for j = 1, #currentShape[i] do
      if currentShape[i][j] ~= 0 then
        local row = currentShapeRow + i - 1
        local column = currentShapeColumn + j - 1
        board[row][column] = currentShapeColor
      end
    end
  end
end

-- Removes completed rows from the board and shifts the rows above them down
local function removeCompletedRows()
  local rowsToRemove = {}

  -- Find rows that are completed
  for row = 1, NUM_ROWS do
    local isCompleted = true
    for column = 1, NUM_COLUMNS do
      if not board[row][column] then
        isCompleted = false
        break
      end
    end
    if isCompleted then
      table.insert(rowsToRemove, row)
    end
  end

  -- Add to score based on how many rows to remove
  score = score + #rowsToRemove
  -- Remove completed rows and shift the rows above them down
  for i = #rowsToRemove, 1, -1 do
    local row = rowsToRemove[i]
    for r = row, 2, -1 do
      for c = 1, NUM_COLUMNS do
        board[r][c] = board[r - 1][c]
      end
    end
    for c = 1, NUM_COLUMNS do
      board[1][c] = nil
    end
  end
end

-- Places current shape, clears completed rows, then selects a new shape
local function selectNewShape()
  placeShape()
  removeCompletedRows()
  currentShape, currentShapeColor = createShape()
  currentShapeRow = 1
  currentShapeColumn = math.floor(NUM_COLUMNS / 2)
end

-- Used to restart the game
local function restartGame()
  score = 0
  board = {}
  for row = 1, NUM_ROWS do
    board[row] = {}
    for column = 1, NUM_COLUMNS do
      board[row][column] = nil
    end
  end
  currentShape, currentShapeColor = createShape()
  currentShapeRow = 1
  currentShapeColumn = math.floor(NUM_COLUMNS / 2)
  love.keyboard.setKeyRepeat(true)
  gameOver = false
end

-- LOVE functions

-- Initialize the game
function love.load()
  love.window.setTitle("Tetris")
  love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)

  -- Initialize the game variables
  board = {}
  for row = 1, NUM_ROWS do
    board[row] = {}
    for column = 1, NUM_COLUMNS do
      board[row][column] = nil
    end
  end
  currentShape, currentShapeColor = createShape()
  currentShapeRow = 1
  currentShapeColumn = math.floor(NUM_COLUMNS / 2)

  love.keyboard.setKeyRepeat(true)
end

-- Update the game
function love.update(dt)
  -- if it's game over, don't run this
  if gameOver then
    return
  end
  -- Update the timer
  timer = timer + dt

  if timer >= interval then
    -- Move the current shape down if possible
    if canMoveDown() then
      currentShapeRow = currentShapeRow + 1
      timer = 0
    else
      selectNewShape()
    end
  end

  -- End the game if the current shape has collided with another block and reached the top of the board
  if not canPlaceShape(currentShape, currentShapeRow, currentShapeColumn) and currentShapeRow == 1 then
    love.event.quit()
  end
end

function love.draw()
  if gameOver then
    love.graphics.printf(string.format("Score: %d", score), 50, 200, 100, "center")
    love.graphics.printf("Press Q to quit, R to restart", 50, 0, 100, "center")
    return
  end
  -- Draw the game board
  drawBoard()

  -- Draw the current shape
  for i = 1, #currentShape do
    for j = 1, #currentShape[i] do
      if currentShape[i][j] ~= 0 then
        drawBlock(currentShapeColor, currentShapeRow + i - 1, currentShapeColumn + j - 1)
      end
    end
  end
end

-- Keybindings
function love.keypressed(key)
  if key == "q" then
    love.event.quit()
  end
  if gameOver == true and key == "r" then
    restartGame()
  elseif key == "left" and canMoveLeft() then
    currentShapeColumn = currentShapeColumn - 1
  elseif key == "right" and canMoveRight() then
    currentShapeColumn = currentShapeColumn + 1
  elseif key == "down" then
    if canMoveDown() then
      currentShapeRow = currentShapeRow + 1
    else
      selectNewShape()
    end
  elseif key == "up" then
    rotateShapeClockwise()
  end
end

function love.quit()
  local readyToQuit = not gameOver
  if not gameOver then
    gameOver = true
    love.graphics.setColor(SHAPE_COLORS[math.random(#SHAPE_COLORS)])
    love.keyboard.setKeyRepeat(false)
  end
  return readyToQuit
end
