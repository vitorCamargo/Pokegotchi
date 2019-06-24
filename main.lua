local game = require('classes/game')

local mainBackground = love.graphics.newImage('/assets/background/1.png')
local gameDayBackground = love.graphics.newImage('/assets/background/backgroundDayGame.png')
local gameNightBackground = love.graphics.newImage('/assets/background/backgroundNightGame.png')
local titleFont = '/assets/fonts/title.ttf'
local pixelFont = '/assets/fonts/pixel.ttf'

local soundBackground = '/assets/sounds/background.mp3'
local gameDaySoundBackground = '/assets/sounds/gameDayBackground.mp3'
local gameNightSoundBackground = '/assets/sounds/gameNightBackground.mp3'
local actionSound = '/assets/sounds/action.mp3'
local changePokemonSound = '/assets/sounds/ditto.mp3'
local saveGameSound = '/assets/sounds/saveGame.mp3'
local isSickSound = '/assets/sounds/sick.mp3'
local recoverySound = '/assets/sounds/recovery.mp3'
local songPlaying = 'backgroundSong'

local timer = 0
local timerUpdate = 0
local timerSickness = 0

nameNewPokemon = ''

local gameState = 'mainPage'

function love.load()
    cursor = love.mouse.getSystemCursor('hand')
    game = game:new()

    math.randomseed(os.time())

    -- Song
    sourceAudio = love.audio.newSource(love.sound.newSoundData(soundBackground))
    sourceAudio:setLooping(true)
    sourceAudio:play()

    if not love.filesystem.getInfo('data.lua') then
        love.filesystem.newFile('data.lua')
        love.filesystem.write('data.lua', '')
    else
        indexPokemon = 1
        for lines in love.filesystem.lines('data.lua') do
            local params = {}

            for p in string.gmatch(lines, '([^;]*);') do
                table.insert(params, p)
            end

            game:addPokemon(params[1], params[2], params[3], params[4], params[5], params[6], params[7], params[8], params[9], params[10])
            game.pokemons[indexPokemon]:updateStats()
            indexPokemon = indexPokemon + 1
        end
        love.filesystem.write('data.lua', game:saveInFile())
    end
end

function love.update( dt )
    timer = timer + dt
    timerUpdate = timerUpdate + dt
    timerSickness = timerSickness + dt

    changeMainBackground(dt)
    updateFilesAndStats(dt)
    verifySickness(dt)
end

function love.draw()
    if gameState == 'mainPage' then drawMainPage()
    elseif gameState == 'choosePokemon' then drawChoosePokemon()
    elseif gameState == 'pokemonSettings' then drawPokemonSettings()
    elseif gameState == 'createNewPokemon' then drawCreateNewPokemon()
    elseif gameState == 'gameMainPage' then drawGameMainPage()
    else error('gameState is not a valid state.') end
end

function drawMainPage()
    -- Background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(mainBackground, x, y)

    -- Title
    love.graphics.setColor(0.980392157, 0.784313725, 0.231372549)
    love.graphics.setNewFont(titleFont, 50)
    love.graphics.printf('PoKéGotchi', 0, love.graphics.getHeight()/2 - 60, love.graphics.getWidth(), 'center')

    -- Subtitle
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(pixelFont, 20)
    love.graphics.printf('PRESS ANY KEY..', 0, love.graphics.getHeight()/2 + 80, love.graphics.getWidth(), 'center')

    -- After key is Pressed/Released
    function love.keyreleased( key )
        if gameState == 'mainPage' then
            gameState = 'choosePokemon'
            love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))
        end
    end
    
    function love.mousereleased( z, y, button )
        if gameState == 'mainPage' then
            gameState = 'choosePokemon'
            love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))
        end
    end
end

function drawChoosePokemon()
    -- Background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(mainBackground, x, y)

    local x, y = love.mouse.getPosition()

    -- Title
    love.graphics.setColor(0.980392157, 0.784313725, 0.231372549)
    love.graphics.setNewFont(titleFont, 40)
    love.graphics.printf('PoKéGotchi', 0, 10, love.graphics.getWidth(), 'center')
    
    -- Subtitle
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(pixelFont, 20)
    love.graphics.printf('PICK OR ADD ONE POKEMON', 0, 80, love.graphics.getWidth(), 'center')

    -- Games Loaded ('till 3 games) | Slot 1
    if table.getn(game.pokemons) >= 1 then
        love.graphics.printf(game.pokemons[1].name, 0, love.graphics.getHeight()/2 - 50, love.graphics.getWidth(), 'center')

        local f = love.graphics.getFont()
        fwSlot1 = f:getWidth(game.pokemons[1].name)
        fhSlot1 = f:getHeight()
    end

    -- Slot 2
    if table.getn(game.pokemons) >= 2 then
        love.graphics.printf(game.pokemons[2].name, 0, love.graphics.getHeight()/2 - 10, love.graphics.getWidth(), 'center')

        local f = love.graphics.getFont()
        fwSlot2 = f:getWidth(game.pokemons[2].name)
        fhSlot2 = f:getHeight()
    end

    -- Slot 3
    if table.getn(game.pokemons) >= 3 then
        love.graphics.printf(game.pokemons[3].name, 0, love.graphics.getHeight()/2 + 30, love.graphics.getWidth(), 'center')

        local f = love.graphics.getFont()
        fwSlot3 = f:getWidth(game.pokemons[3].name)
        fhSlot3 = f:getHeight()
    end

    -- New Pokemons
    if table.getn(game.pokemons) < 3 then
        love.graphics.printf('+ New Poke', 0, love.graphics.getHeight() - 50, love.graphics.getWidth(), 'center')

        local f = love.graphics.getFont()
        fwSlotNew = f:getWidth('+ New Poke')
        fhSlotNew = f:getHeight()
    end
    
    -- Function to Click in Slots/New Poke
    function love.mousepressed( z, y, button )
        if gameState == 'choosePokemon' then
            if table.getn(game.pokemons) < 3 and (y >= love.graphics.getHeight() - 50 and y <= love.graphics.getHeight() - 50 + fhSlotNew) and (x >= (love.graphics.getWidth() - fwSlotNew)/2 and x <= (love.graphics.getWidth() - fwSlotNew)/2 + fwSlotNew) then
                love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))
                nameNewPokemon = ''
                gameState = 'createNewPokemon'
            elseif table.getn(game.pokemons) >= 1 and (y >= love.graphics.getHeight()/2 - 50 and y <= love.graphics.getHeight()/2 - 50 + fhSlot1) and (x >= (love.graphics.getWidth() - fwSlot1)/2 and x <= (love.graphics.getWidth() - fwSlot1)/2 + fwSlot1) then
                love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))
                game:setCurrentPokemon(1)
                gameState = 'pokemonSettings'
            elseif table.getn(game.pokemons) >= 2 and (y >= love.graphics.getHeight()/2 - 10 and y <= love.graphics.getHeight()/2 - 10 + fhSlot2) and (x >= (love.graphics.getWidth() - fwSlot2)/2 and x <= (love.graphics.getWidth() - fwSlot2)/2 + fwSlot2) then
                love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))
                game:setCurrentPokemon(2)
                gameState = 'pokemonSettings'
            elseif table.getn(game.pokemons) >= 3 and (y >= love.graphics.getHeight()/2 + 30 and y <= love.graphics.getHeight()/2 + 30 + fhSlot3) and (x >= (love.graphics.getWidth() - fwSlot3)/2 and x <= (love.graphics.getWidth() - fwSlot3)/2 + fwSlot3) then
                love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))
                game:setCurrentPokemon(3)
                gameState = 'pokemonSettings'
            end
        end
    end

    -- Change Mouse Cursor
    if table.getn(game.pokemons) < 3 and (y >= love.graphics.getHeight() - 50 and y <= love.graphics.getHeight() - 50 + fhSlotNew) and (x >= (love.graphics.getWidth() - fwSlotNew)/2 and x <= (love.graphics.getWidth() - fwSlotNew)/2 + fwSlotNew) then
        love.mouse.setCursor(cursor)
    elseif table.getn(game.pokemons) >= 1 and (y >= love.graphics.getHeight()/2 - 50 and y <= love.graphics.getHeight()/2 - 50 + fhSlot1) and (x >= (love.graphics.getWidth() - fwSlot1)/2 and x <= (love.graphics.getWidth() - fwSlot1)/2 + fwSlot1) then
        love.mouse.setCursor(cursor)
    elseif table.getn(game.pokemons) >= 2 and (y >= love.graphics.getHeight()/2 - 10 and y <= love.graphics.getHeight()/2 - 10 + fhSlot2) and (x >= (love.graphics.getWidth() - fwSlot2)/2 and x <= (love.graphics.getWidth() - fwSlot2)/2 + fwSlot2) then
        love.mouse.setCursor(cursor)
    elseif table.getn(game.pokemons) >= 3 and (y >= love.graphics.getHeight()/2 + 30 and y <= love.graphics.getHeight()/2 + 30 + fhSlot3) and (x >= (love.graphics.getWidth() - fwSlot3)/2 and x <= (love.graphics.getWidth() - fwSlot3)/2 + fwSlot3) then
        love.mouse.setCursor(cursor)
    else love.mouse.setCursor() end
end

function drawPokemonSettings()
    -- Background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(mainBackground, x, y)

    local x, y = love.mouse.getPosition()

    -- Title
    love.graphics.setColor(0.980392157, 0.784313725, 0.231372549)
    love.graphics.setNewFont(titleFont, 40)
    love.graphics.printf('PoKéGotchi', 0, 10, love.graphics.getWidth(), 'center')
    
    -- Subtitle (Name of Pokemon)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(pixelFont, 20)
    love.graphics.print(game:getCurrentPokemon().name, 10, 130)

    -- Load Game
    love.graphics.print('LOAD GAME', 40, 200)

    local f = love.graphics.getFont()
    fwLoad = f:getWidth('LOAD GAME')
    fhLoad = f:getHeight()

    -- Delete Game
    love.graphics.print('DELETE GAME', 40, 240)

    local f = love.graphics.getFont()
    fwDelete = f:getWidth('DELETE GAME')
    fhDelete = f:getHeight()

    -- Back to Menu
    love.graphics.print('BACK', 40, 280)

    local f = love.graphics.getFont()
    fwBack = f:getWidth('BACK')
    fhBack = f:getHeight()
    
    -- Function to Click in Slots/New Poke
    function love.mousepressed( z, y, button )
        if gameState == 'pokemonSettings' then
            if y >= 200 and y <= 200 + fhLoad and x >= 40 and x <= 40 + fwLoad then
                love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))
                gameState = 'gameMainPage'
            elseif y >= 240 and y <= 240 + fhDelete and x >= 40 and x <= 40 + fwDelete then
                game:removePokemon(game.currentPokemon)
                love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))
                love.filesystem.write('data.lua', game:saveInFile())

                gameState = 'choosePokemon'
            elseif y >= 280 and y <= 280 + fhBack and x >= 40 and x <= 40 + fwBack then
                love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))
                gameState = 'choosePokemon'
            end
        end
    end

    -- Change Mouse Cursor
    if y >= 200 and y <= 200 + fhLoad and x >= 40 and x <= 40 + fwLoad then
        love.mouse.setCursor(cursor)
    elseif y >= 240 and y <= 240 + fhDelete and x >= 40 and x <= 40 + fwDelete then
        love.mouse.setCursor(cursor)
    elseif y >= 280 and y <= 280 + fhBack and x >= 40 and x <= 40 + fwBack then
        love.mouse.setCursor(cursor)
    else love.mouse.setCursor() end
end

function drawCreateNewPokemon()
    -- Background
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(mainBackground, x, y)

    local x, y = love.mouse.getPosition()

    -- Title
    love.graphics.setColor(0.980392157, 0.784313725, 0.231372549)
    love.graphics.setNewFont(titleFont, 40)
    love.graphics.printf('PoKéGotchi', 0, 10, love.graphics.getWidth(), 'center')
    
    -- Subtitle (Name of Pokemon)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(pixelFont, 20)
    love.graphics.print('TYPE THE NAME OF', 10, 100)
    love.graphics.print('YOUR NEW POKÉ', 10, 125)    

    -- Name of New Pokemon
    love.graphics.print('/ ' .. nameNewPokemon, 10, 200)

    -- Back to Menu
    love.graphics.print('BACK', 40, love.graphics.getHeight() - 30)

    local f = love.graphics.getFont()
    fwBack = f:getWidth('BACK')
    fhBack = f:getHeight()

    -- Confirm Action
    if nameNewPokemon ~= nil and nameNewPokemon ~= '' then
        local f = love.graphics.getFont()
        fwCreate = f:getWidth('CREATE')
        fhCreate = f:getHeight()

        love.graphics.print('CREATE', love.graphics.getWidth() - fwCreate - 40, love.graphics.getHeight() - 30)
    end
    
    -- Function to Click in Slots/New Poke
    function love.mousepressed( z, y, button )
        if gameState == 'createNewPokemon' then
            if y >= love.graphics.getHeight() - 30 and y <= love.graphics.getHeight() - 30 + fhBack and x >= 40 and x <= 40 + fwBack then
                love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))
                gameState = 'choosePokemon'
            elseif nameNewPokemon ~= nil and nameNewPokemon ~= '' and y >= love.graphics.getHeight() - 30 and y <= love.graphics.getHeight() - 30 + fhCreate and x >= love.graphics.getWidth() - fwCreate - 40 and x <= love.graphics.getWidth() - fwCreate - 40 + fwCreate then
                love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))

                game:addPokemon(nameNewPokemon)
                game:setCurrentPokemon(table.getn(game.pokemons))
                love.filesystem.write('data.lua', game:saveInFile())

                gameState = "gameMainPage"
            end
        end
    end

    -- Change Mouse Cursor
    if y >= love.graphics.getHeight() - 30 and y <= love.graphics.getHeight() - 30 + fhBack and x >= 40 and x <= 40 + fwBack then
        love.mouse.setCursor(cursor)
    elseif nameNewPokemon ~= nil and nameNewPokemon ~= '' and y >= love.graphics.getHeight() - 30 and y <= love.graphics.getHeight() - 30 + fhCreate and x >= love.graphics.getWidth() - fwCreate - 40 and x <= love.graphics.getWidth() - fwCreate - 40 + fwCreate then
        love.mouse.setCursor(cursor)
    else love.mouse.setCursor() end
    
    -- Get the name of new Pokémon
    function love.textinput( t )
        if gameState == 'createNewPokemon' then
            nameNewPokemon = nameNewPokemon .. t
        end
    end

    function love.keypressed( key )
        if gameState == 'createNewPokemon' then
            if key == 'backspace' then
                nameNewPokemon = nameNewPokemon:sub(1, -2)
            elseif key == 'return' and nameNewPokemon ~= nil and nameNewPokemon ~= '' then
                love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))

                game:addPokemon(nameNewPokemon)
                game:setCurrentPokemon(table.getn(game.pokemons))
                love.filesystem.write('data.lua', game:saveInFile())

                gameState = "gameMainPage"
            end
        end
    end
end

function drawGameMainPage()
    local currentPokemon = game:getCurrentPokemon()

    -- Background
    love.graphics.setColor(1, 1, 1, 1)
    if currentPokemon:isSleeping() == 'true' then
        love.graphics.draw(gameNightBackground, x, y)
    else
        love.graphics.draw(gameDayBackground, x, y)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(pixelFont, 20)

    local x, y = love.mouse.getPosition()

    -- Change Song
    if songPlaying == 'backgroundSong' or (songPlaying == 'gameDaySongBackground' and currentPokemon:isSleeping() == 'true') or (songPlaying == 'gameNightSongBackground' and currentPokemon:isSleeping() == 'false') then
        sourceAudio:stop()
        if currentPokemon:isSleeping() == 'true' then
            sourceAudio = love.audio.newSource(love.sound.newSoundData(gameNightSoundBackground))
            songPlaying = 'gameNightSongBackground'
        else
            sourceAudio = love.audio.newSource(love.sound.newSoundData(gameDaySoundBackground))
            songPlaying = 'gameDaySongBackground'
        end
        sourceAudio:setLooping(true)
        sourceAudio:play()
    end

    -- Back to Menu
    love.graphics.print('BACK', 10, 10)

    local f = love.graphics.getFont()
    fwBack = f:getWidth('BACK')
    fhBack = f:getHeight()

    -- Menu
    love.graphics.draw(love.graphics.newImage('assets/items/play.png'), 5, love.graphics.getHeight()/2 - 130, 0, 1.3, 1.3)
    love.graphics.draw(love.graphics.newImage('assets/items/food.png'), 5, love.graphics.getHeight()/2 - 90, 0, 1.3, 1.3)
    love.graphics.draw(love.graphics.newImage('assets/items/clean.png'), 8, love.graphics.getHeight()/2 - 45, 0, 1.3, 1.3)
    love.graphics.draw(love.graphics.newImage('assets/items/medicine.png'), 5, love.graphics.getHeight()/2, 0, 1.3, 1.3)
    love.graphics.draw(love.graphics.newImage('assets/items/sleep.png'), 8, love.graphics.getHeight()/2 + 50, 0, 1.3, 1.3)

    -- Change Pokemon
    love.graphics.draw(love.graphics.newImage('assets/items/master-ball.png'), love.graphics.getWidth() - 50, love.graphics.getHeight() - 50, 0, 1.5, 1.5)

    -- Pokémon
    local pokemonImage = '/assets/pokemons/'

    if currentPokemon:isSleeping() == 'true' then pokemonImage = pokemonImage .. '/sleeping/' end
    if currentPokemon:isSick() then pokemonImage = pokemonImage .. '/sick/' end
    
    love.graphics.draw(love.graphics.newImage(pokemonImage .. currentPokemon.image), love.graphics.getWidth()/2 - 30, love.graphics.getHeight() - 180, 0, 1.9, 1.9)

    -- Stats
    love.graphics.setNewFont(pixelFont, 14)
    local f = love.graphics.getFont()
    fhStats = f:getHeight()

    -- Happiness Stats
    love.graphics.setColor(1, 1, 1)
    fwStats = f:getWidth('Happiness (' .. math.floor(currentPokemon.happiness) .. '%)')

    love.graphics.print('Happiness (' .. math.floor(currentPokemon.happiness) .. '%)', love.graphics.getWidth() - fwStats - 20, 10)
    love.graphics.rectangle("line", love.graphics.getWidth() - 220, fhStats + 10, 200, 10, 5, 5)

    stats = currentPokemon.happiness * 2
    if stats == 0 then stats = 10 end
    if stats <= 50 then love.graphics.setColor(0.960784314, 0.231372549, 0.341176471)
    elseif stats <= 140 then love.graphics.setColor(1, 0.658823529, 0.00392156863)
    else love.graphics.setColor(0.0196078431, 0.768627451, 0.419607843) end

    love.graphics.rectangle("fill", love.graphics.getWidth() - 220, fhStats + 10, stats, 10, 5)

    -- Energy Stats
    love.graphics.setColor(1, 1, 1)
    fwStats = f:getWidth('Energy (' .. math.floor(currentPokemon.energy) .. '%)')

    love.graphics.print('Energy (' .. math.floor(currentPokemon.energy) .. '%)', love.graphics.getWidth() - fwStats - 20, 60)
    love.graphics.rectangle("line", love.graphics.getWidth() - 220, fhStats + 60, 200, 10, 5, 5)

    stats = currentPokemon.energy * 2
    if stats == 0 then stats = 10 end
    if stats <= 50 then love.graphics.setColor(0.960784314, 0.231372549, 0.341176471)
    elseif stats <= 140 then love.graphics.setColor(1, 0.658823529, 0.00392156863)
    else love.graphics.setColor(0.0196078431, 0.768627451, 0.419607843) end

    love.graphics.rectangle("fill", love.graphics.getWidth() - 220, fhStats + 60, stats, 10, 5)

    -- Healthy Stats
    love.graphics.setColor(1, 1, 1)
    fwStats = f:getWidth('Healthy (' .. math.floor(currentPokemon.healthiness) .. '%)')

    love.graphics.print('Healthy (' .. math.floor(currentPokemon.healthiness) .. '%)', love.graphics.getWidth() - fwStats - 20, 110)
    love.graphics.rectangle("line", love.graphics.getWidth() - 220, fhStats + 110, 200, 10, 5, 5)

    stats = currentPokemon.healthiness * 2
    if stats == 0 then stats = 10 end
    if stats <= 50 then love.graphics.setColor(0.960784314, 0.231372549, 0.341176471)
    elseif stats <= 140 then love.graphics.setColor(1, 0.658823529, 0.00392156863)
    else love.graphics.setColor(0.0196078431, 0.768627451, 0.419607843) end

    love.graphics.rectangle("fill", love.graphics.getWidth() - 220, fhStats + 110, stats, 10, 5)

    -- Dirty Stats
    love.graphics.setColor(1, 1, 1)
    fwStats = f:getWidth('Clean (' .. 100 - math.floor(currentPokemon.dirt) .. '%)')

    love.graphics.print('Clean (' .. 100 - math.floor(currentPokemon.dirt) .. '%)', love.graphics.getWidth() - fwStats - 20, 160)
    love.graphics.rectangle("line", love.graphics.getWidth() - 220, fhStats + 160, 200, 10, 5, 5)

    stats = 200 - currentPokemon.dirt * 2
    if stats == 0 then stats = 10 end
    if stats <= 50 then love.graphics.setColor(0.960784314, 0.231372549, 0.341176471)
    elseif stats <= 140 then love.graphics.setColor(1, 0.658823529, 0.00392156863)
    else love.graphics.setColor(0.0196078431, 0.768627451, 0.419607843) end

    love.graphics.rectangle("fill", love.graphics.getWidth() - 220, fhStats + 160, stats, 10, 5)

    -- Hunger Stats
    love.graphics.setColor(1, 1, 1)
    fwStats = f:getWidth('Pleased (' .. 100 - math.floor(currentPokemon.hunger) .. '%)')

    love.graphics.print('Pleased (' .. 100 -math.floor(currentPokemon.hunger) .. '%)', love.graphics.getWidth() - fwStats - 20, 210)
    love.graphics.rectangle("line", love.graphics.getWidth() - 220, fhStats + 210, 200, 10, 5, 5)

    stats = 200 - currentPokemon.hunger * 2
    if stats == 0 then stats = 10 end
    if stats <= 50 then love.graphics.setColor(0.960784314, 0.231372549, 0.341176471)
    elseif stats <= 140 then love.graphics.setColor(1, 0.658823529, 0.00392156863)
    else love.graphics.setColor(0.0196078431, 0.768627451, 0.419607843) end

    love.graphics.rectangle("fill", love.graphics.getWidth() - 220, fhStats + 210, stats, 10, 5)

    -- Function when click in anypoint
    function love.mousepressed( z, y, button )
        if gameState == 'gameMainPage' then
            if y >= 10 and y <= 10 + fhBack and x >= 10 and x <= 10 + fwBack then
                love.audio.play(love.audio.newSource(love.sound.newSoundData(actionSound)))

                sourceAudio:stop()
                sourceAudio = love.audio.newSource(love.sound.newSoundData(soundBackground))
                sourceAudio:setLooping(true)
                sourceAudio:play()
                songPlaying = 'backgroundSong'

                gameState = 'choosePokemon'
            elseif y >= love.graphics.getHeight() - 60 and y <= love.graphics.getHeight() - 60 + 45 and x >= love.graphics.getWidth() - 60 and x <= love.graphics.getWidth() - 60 + 45 then
                love.audio.play(love.audio.newSource(love.sound.newSoundData(changePokemonSound)))

                local newPokemon = math.random(1, 649)
                currentPokemon:setImage(newPokemon .. '.png')
                love.filesystem.write('data.lua', game:saveInFile())
            elseif x >= 5 and x <= 35 and y >= love.graphics.getHeight()/2 - 130 and y <= love.graphics.getHeight()/2 - 100 then
                -- Play
            elseif x >= 5 and x <= 35 and y >= love.graphics.getHeight()/2 - 90 and y <= love.graphics.getHeight()/2 - 60 + 45 then
                -- Food
            elseif x >= 8 and x <= 32 and y >= love.graphics.getHeight()/2 - 45 and y <= love.graphics.getHeight()/2 - 21 then
                -- Clean
            elseif x >= 5 and x <= 35 and y >= love.graphics.getHeight()/2 and y <= love.graphics.getHeight()/2 + 30 then
                -- Medicine
            elseif x >= 8 and x <= 32 and y >= love.graphics.getHeight()/2 + 50 and y <= love.graphics.getHeight()/2 + 80 then
                if currentPokemon:isSleeping() == 'true' then currentPokemon:setSleeping('false')
                else currentPokemon:setSleeping('true') end
            end
        end
    end

    -- Change Mouse Cursor
    if y >= 10 and y <= 10 + fhBack and x >= 10 and x <= 10 + fwBack then
        love.mouse.setCursor(cursor)
    elseif y >= love.graphics.getHeight() - 60 and y <= love.graphics.getHeight() - 60 + 45 and x >= love.graphics.getWidth() - 60 and x <= love.graphics.getWidth() - 60 + 45 then
        love.mouse.setCursor(cursor)
    elseif x >= 5 and x <= 35 and y >= love.graphics.getHeight()/2 - 130 and y <= love.graphics.getHeight()/2 - 100 then
        love.mouse.setCursor(cursor)
    elseif x >= 5 and x <= 35 and y >= love.graphics.getHeight()/2 - 90 and y <= love.graphics.getHeight()/2 - 60 + 45 then
        love.mouse.setCursor(cursor)
    elseif x >= 8 and x <= 32 and y >= love.graphics.getHeight()/2 - 45 and y <= love.graphics.getHeight()/2 - 21 then
        love.mouse.setCursor(cursor)
    elseif x >= 5 and x <= 35 and y >= love.graphics.getHeight()/2 and y <= love.graphics.getHeight()/2 + 30 then
        love.mouse.setCursor(cursor)
    elseif x >= 8 and x <= 32 and y >= love.graphics.getHeight()/2 + 50 and y <= love.graphics.getHeight()/2 + 80 then
        love.mouse.setCursor(cursor)
    else love.mouse.setCursor() end
end

function changeMainBackground( dt )
    mainBackground = love.graphics.newImage('/assets/background/' .. tonumber(string.format('%.0f', timer)) % 20 + 1 .. '.png')
end

function updateFilesAndStats( dt )
    if game.currentPokemon and tonumber(string.format('%.0f', timerUpdate)) % 11 == 10 then
        love.audio.play(love.audio.newSource(love.sound.newSoundData(saveGameSound)))
        print('updating...')
        game.pokemons[game.currentPokemon]:updateStats()
        love.filesystem.write('data.lua', game:saveInFile())
        timerUpdate = 0
    end
end

function verifySickness( dt )
    if game.currentPokemon and gameState == 'gameMainPage' and tonumber(string.format('%.0f', timerSickness)) % 6 == 5 then
        if game.pokemons[game.currentPokemon]:isSick() then love.audio.play(love.audio.newSource(love.sound.newSoundData(isSickSound))) end
        timerSickness = 0
    end
end