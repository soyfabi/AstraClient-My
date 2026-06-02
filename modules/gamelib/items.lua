ItemsDatabase = ItemsDatabase or {}

ItemsDatabase.rarityColors = ItemsDatabase.rarityColors or {
  gold = '#F0F000',
  yellow = '#F0F000',
  purple = '#FF68FF',
  blue = '#20A0FF',
  green = '#00F000',
  grey = '#AAAAAA',
  white = '#F0F0F0'
}

ItemsDatabase.rarityFrames = ItemsDatabase.rarityFrames or {
  gold = '/images/ui/rarity_square_gold',
  purple = '/images/ui/rarity_square_purple',
  blue = '/images/ui/rarity_square_blue',
  green = '/images/ui/rarity_square_green',
  white = '/images/ui/rarity_square_white'
}

ItemsDatabase.rarityCornerFrames = ItemsDatabase.rarityCornerFrames or {
  gold = '/images/ui/rarity_corner_gold',
  purple = '/images/ui/rarity_corner_purple',
  blue = '/images/ui/rarity_corner_blue',
  green = '/images/ui/rarity_corner_green',
  white = '/images/ui/rarity_corner_white'
}

ItemsDatabase.fixedValues = ItemsDatabase.fixedValues or {
  [3031] = 1,
  [3035] = 100,
  [3043] = 10000
}

ItemsDatabase.serverValues = ItemsDatabase.serverValues or {}
ItemsDatabase.serverDetails = ItemsDatabase.serverDetails or {}

function ItemsDatabase.registerServerItemValue(itemId, value)
  itemId = tonumber(itemId)
  value = tonumber(value)
  if itemId and itemId > 0 and value and value > 0 then
    ItemsDatabase.serverValues[itemId] = math.max(ItemsDatabase.serverValues[itemId] or 0, value)
  end
end

function ItemsDatabase.registerServerItemDetails(itemId, details)
  itemId = tonumber(itemId)
  if not itemId or itemId <= 0 or type(details) ~= 'table' then
    return
  end

  ItemsDatabase.serverDetails[itemId] = details

  local value = tonumber(details.defaultValue) or 0
  if value <= 0 then
    value = tonumber(details.averageMarketValue) or 0
  end
  if value > 0 then
    ItemsDatabase.registerServerItemValue(itemId, value)
  end
end

function ItemsDatabase.getServerItemDetails(itemId)
  return ItemsDatabase.serverDetails[tonumber(itemId) or 0]
end

function ItemsDatabase.hasServerItemDetails(itemId)
  return ItemsDatabase.getServerItemDetails(itemId) ~= nil
end

local function safeCall(object, method)
  if not object or not object[method] then
    return nil
  end

  local ok, value = pcall(function()
    return object[method](object)
  end)

  if ok then
    return tonumber(value) or 0
  end

  return nil
end

local function getNpcPriceValue(item)
  if not item or not item.getNPCSaleData then
    return 0
  end

  local ok, npcData = pcall(function()
    return item:getNPCSaleData()
  end)

  if not ok or type(npcData) ~= 'table' then
    return 0
  end

  local bestBuyPrice = 0
  local bestSellPrice = 0
  for _, offer in pairs(npcData) do
    if type(offer) == 'table' then
      local buyPrice = tonumber(offer.buyPrice or offer.buy or offer.itemBuyPrice) or 0
      local sellPrice = tonumber(offer.salePrice or offer.sellPrice or offer.sell or offer.itemSellPrice) or 0
      bestBuyPrice = math.max(bestBuyPrice, buyPrice)
      bestSellPrice = math.max(bestSellPrice, sellPrice)
    end
  end

  return bestSellPrice > 0 and bestSellPrice or bestBuyPrice
end

function ItemsDatabase.hasColorLootMarkup(text)
  return type(text) == 'string' and text:find('{%d+:?%d*|.-}') ~= nil
end

function ItemsDatabase.getItemValue(itemOrId)
  local item = itemOrId
  local itemId = tonumber(itemOrId)

  if type(itemOrId) ~= 'number' and type(itemOrId) ~= 'string' and itemOrId and itemOrId.getId then
    local ok, id = pcall(function()
      return itemOrId:getId()
    end)

    if ok then
      itemId = tonumber(id)
    end
  end

  if itemId and ItemsDatabase.fixedValues[itemId] then
    return ItemsDatabase.fixedValues[itemId]
  end

  local details = itemId and ItemsDatabase.getServerItemDetails(itemId) or nil
  if details then
    local value = tonumber(details.defaultValue) or 0
    if value > 0 then
      return value
    end
    value = tonumber(details.averageMarketValue) or 0
    if value > 0 then
      return value
    end
  end

  if itemId and ItemsDatabase.serverValues[itemId] then
    return ItemsDatabase.serverValues[itemId]
  end

  local prices = Analyzer and Analyzer.analyzers and Analyzer.analyzers.customPrices or {}
  local customValue = itemId and (prices[tostring(itemId)] or prices[itemId])
  if tonumber(customValue) and tonumber(customValue) > 0 then
    return tonumber(customValue)
  end

  if type(itemOrId) == 'number' or type(itemOrId) == 'string' then
    item = itemId and Item and Item.create and Item.create(itemId, 1) or nil
  end

  local value = safeCall(item, 'getPriceValue')
  if value and value > 0 then
    return value
  end

  value = safeCall(item, 'getAverageMarketValue')
  if value and value > 0 then
    return value
  end

  value = safeCall(item, 'getDefaultValue')
  if value and value > 0 then
    return value
  end

  value = getNpcPriceValue(item)
  if value and value > 0 then
    return value
  end

  local cyclopediaItems = modules and modules.game_cyclopedia and modules.game_cyclopedia.CyclopediaItems
  if cyclopediaItems and cyclopediaItems.getCurrentItemValue and item then
    local ok, currentValue = pcall(function()
      return cyclopediaItems.getCurrentItemValue(item)
    end)

    if ok and tonumber(currentValue) and tonumber(currentValue) > 0 then
      return tonumber(currentValue)
    end
  end

  local thingType = itemId and g_things and g_things.findItemTypeByClientId and g_things.findItemTypeByClientId(itemId)
  value = safeCall(thingType, 'getMeanPrice')
  if value and value > 0 then
    return value
  end

  return 0
end

function ItemsDatabase.getRarityForValue(value)
  value = tonumber(value) or 0

  if value >= 1000000 then
    return 'gold'
  elseif value >= 100000 then
    return 'purple'
  elseif value >= 10000 then
    return 'blue'
  elseif value >= 1000 then
    return 'green'
  elseif value >= 50 then
    return 'white'
  end

  return nil
end

function ItemsDatabase.getColorForValue(value)
  value = tonumber(value) or 0

  if value >= 1000000 then
    return ItemsDatabase.rarityColors.gold
  elseif value >= 100000 then
    return ItemsDatabase.rarityColors.purple
  elseif value >= 10000 then
    return ItemsDatabase.rarityColors.blue
  elseif value >= 1000 then
    return ItemsDatabase.rarityColors.green
  elseif value >= 50 then
    return ItemsDatabase.rarityColors.grey
  end

  return ItemsDatabase.rarityColors.white
end

function ItemsDatabase.getItemColor(itemOrId)
  return ItemsDatabase.getColorForValue(ItemsDatabase.getItemValue(itemOrId))
end

function ItemsDatabase.getRarityFrame(itemOrId, corner)
  local rarity = ItemsDatabase.getRarityForValue(ItemsDatabase.getItemValue(itemOrId))
  if not rarity then
    return nil
  end

  local frames = corner and ItemsDatabase.rarityCornerFrames or ItemsDatabase.rarityFrames
  return frames[rarity]
end

function ItemsDatabase.setColorLootMessage(text, defaultColor)
  local result = {}
  local lastEnd = 1

  defaultColor = defaultColor or ItemsDatabase.rarityColors.white

  local function add(textPart, color)
    if textPart and textPart ~= '' then
      table.insert(result, textPart)
      table.insert(result, color or defaultColor)
    end
  end

  if type(text) ~= 'string' then
    return result
  end

  for start, itemId, itemValue, itemText, finish in text:gmatch('(){(%d+):?(%d*)|(.-)}()') do
    itemId = tonumber(itemId)
    itemValue = tonumber(itemValue)
    if itemId and itemValue and itemValue > 0 then
      ItemsDatabase.registerServerItemValue(itemId, itemValue)
    end

    add(text:sub(lastEnd, start - 1), defaultColor)
    add(itemText, itemValue and ItemsDatabase.getColorForValue(itemValue) or ItemsDatabase.getItemColor(itemId))
    lastEnd = finish
  end

  add(text:sub(lastEnd), defaultColor)
  return result
end

function ItemsDatabase.setRarityItem(widget, item, corner)
  if not widget or not widget.setImageSource then
    return
  end

  if widget.rarityDefaultImageSource == nil and widget.getImageSource then
    widget.rarityDefaultImageSource = widget:getImageSource()
  end

  local frame = item and ItemsDatabase.getRarityFrame(item, corner)
  if frame then
    widget:setImageSource(frame)
  elseif widget.rarityDefaultImageSource ~= nil then
    widget:setImageSource(widget.rarityDefaultImageSource)
  end
end

local function clampTier(tier, maxTier)
  tier = tonumber(tier) or 0
  return math.min(math.max(tier, 0), maxTier)
end

function ItemsDatabase.getTierClip(tier, big)
  local width = big and 18 or 9
  local height = big and 16 or 8
  local normalizedTier = clampTier(tier, 10)

  if normalizedTier <= 0 then
    return nil
  end

  return {
    x = (normalizedTier - 1) * width,
    y = 0,
    width = width,
    height = height
  }
end

function ItemsDatabase.setTier(widget, item, big)
  if not widget or not widget.tier then
    return
  end

  if not g_game.getFeature(GameThingUpgradeClassification) and not g_game.getFeature(GameItemTierByte) then
    widget.tier:setVisible(false)
    return
  end

  if big == nil then
    big = widget:getWidth() > 34
  end

  local tier = 0
  if type(item) == 'number' then
    tier = item
  elseif item and item.getTier then
    local ok, itemTier = pcall(function() return item:getTier() end)
    if ok then
      tier = itemTier or 0
    end
  end

  local clip = ItemsDatabase.getTierClip(tier, big)
  if not clip then
    widget.tier:setVisible(false)
    return
  end

  local size = big and '18 16' or '9 8'
  widget.tier:setImageSource(big and '/images/game/items/tiers-strip-big' or '/images/game/items/tiers-strip')
  widget.tier:setImageClip(clip)
  widget.tier:setImageSize(size)
  widget.tier:setSize(size)
  widget.tier:setVisible(true)
end
