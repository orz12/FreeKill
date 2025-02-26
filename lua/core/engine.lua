-- SPDX-License-Identifier: GPL-3.0-or-later

--- Engine是整个FreeKill赖以运行的核心。
---
--- 它包含了FreeKill涉及的所有武将、卡牌、游戏模式等等
---
--- 同时也提供了许多常用的函数。
---
---@class Engine : Object
---@field public packages table<string, Package> @ 所有拓展包的列表
---@field public package_names string[] @ 含所有拓展包名字的数组，为了方便排序
---@field public skills table<string, Skill> @ 所有的技能
---@field public related_skills table<string, Skill[]> @ 所有技能的关联技能
---@field public global_trigger TriggerSkill[] @ 所有的全局触发技
---@field public global_status_skill table<class, Skill[]> @ 所有的全局状态技
---@field public generals table<string, General> @ 所有武将
---@field public same_generals table<string, string[]> @ 所有同名武将组合
---@field public lords string[] @ 所有主公武将，用于常备主公
---@field public cards Card[] @ 所有卡牌
---@field public translations table<string, table<string, string>> @ 翻译表
---@field public game_modes table<string, GameMode> @ 所有游戏模式
---@field public disabled_packs string[] @ 禁用的拓展包列表
---@field public currentResponsePattern string @ 要求用牌的种类（如要求用特定花色的桃···）
---@field public currentResponseReason string @ 要求用牌的原因（如濒死，被特定牌指定，使用特定技能···）
local Engine = class("Engine")

--- Engine的构造函数。
---
--- 这个函数只应该被执行一次。执行了之后，会创建一个Engine实例，并放入全局变量Fk中。
---@return nil
function Engine:initialize()
  -- Engine should be singleton
  if Fk ~= nil then
    error("Engine has been initialized")
    return
  end

  Fk = self

  self.packages = {}    -- name --> Package
  self.package_names = {}
  self.skills = {}    -- name --> Skill
  self.related_skills = {} -- skillName --> relatedSkill[]
  self.global_trigger = {}
  self.global_status_skill = {}
  self.generals = {}    -- name --> General
  self.same_generals = {}
  self.lords = {}     -- lordName[]
  self.cards = {}     -- Card[]
  self.translations = {}  -- srcText --> translated
  self.game_modes = {}
  self.disabled_packs = {}
  self.disabled_generals = {}
  self.kingdoms = {}

  self:loadPackages()
  self:addSkills(AuxSkills)
end

--- 向Engine中加载一个拓展包。
---
--- 会加载这个拓展包含有的所有武将、卡牌以及游戏模式。
---@param pack Package @ 要加载的拓展包
function Engine:loadPackage(pack)
  assert(pack:isInstanceOf(Package))
  if self.packages[pack.name] ~= nil then
    error(string.format("Duplicate package %s detected", pack.name))
  end
  self.packages[pack.name] = pack
  table.insert(self.package_names, pack.name)

  -- add cards, generals and skills to Engine
  if pack.type == Package.CardPack then
    self:addCards(pack.cards)
  elseif pack.type == Package.GeneralPack then
    self:addGenerals(pack.generals)
  end
  self:addSkills(pack:getSkills())
  self:addGameModes(pack.game_modes)
end

--- 加载所有拓展包。
---
--- Engine会在packages/下搜索所有含有init.lua的文件夹，并把它们作为拓展包加载进来。
---
--- 这样的init.lua可以返回单个拓展包，也可以返回拓展包数组，或者什么都不返回。
---
--- 标包和标准卡牌包比较特殊，它们永远会在第一个加载。
---@return nil
function Engine:loadPackages()
  local directories = FileIO.ls("packages")

  -- load standard & standard_cards first
  self:loadPackage(require("packages.standard"))
  self:loadPackage(require("packages.standard_cards"))
  table.removeOne(directories, "standard")
  table.removeOne(directories, "standard_cards")

  for _, dir in ipairs(directories) do
    if (not string.find(dir, ".disabled")) and FileIO.isDir("packages/" .. dir)
      and FileIO.exists("packages/" .. dir .. "/init.lua") then
      local pack = require(string.format("packages.%s", dir))
      -- Note that instance of Package is a table too
      -- so dont use type(pack) == "table" here
      if type(pack) == "table" then
        if pack[1] ~= nil then
          for _, p in ipairs(pack) do
            self:loadPackage(p)
          end
        else
          self:loadPackage(pack)
        end
      end
    end
  end
end

--- 向翻译表中加载新的翻译表。
---@param t table @ 要加载的翻译表，这是一个 原文 --> 译文 的键值对表
---@param lang string|nil @ 目标语言，默认为zh_CN
function Engine:loadTranslationTable(t, lang)
  assert(type(t) == "table")
  lang = lang or "zh_CN"
  self.translations[lang] = self.translations[lang] or {}
  for k, v in pairs(t) do
    self.translations[lang][k] = v
  end
end

--- 翻译一段文本。其实就是从翻译表中去找
---@param src string @ 要翻译的文本
function Engine:translate(src)
  local lang = Config.language or "zh_CN"
  if not self.translations[lang] then lang = "zh_CN" end
  local ret = self.translations[lang][src]
  return ret or src
end

--- 向Engine中加载一个技能。
---
--- 如果技能是global的，那么同时会将其放到那些global技能表中。
---
--- 如果技能有关联技能，那么递归地加载那些关联技能。
---@param skill Skill @ 要加载的技能
function Engine:addSkill(skill)
  assert(skill.class:isSubclassOf(Skill))
  if self.skills[skill.name] ~= nil then
    error(string.format("Duplicate skill %s detected", skill.name))
  end
  self.skills[skill.name] = skill

  if skill.global then
    if skill:isInstanceOf(TriggerSkill) then
      table.insert(self.global_trigger, skill)
    else
      local t = self.global_status_skill
      t[skill.class] = t[skill.class] or {}
      table.insert(t[skill.class], skill)
    end
  end

  for _, s in ipairs(skill.related_skills) do
    self:addSkill(s)
  end
end

--- 加载一系列技能。
---@param skills Skill[] @ 要加载的技能数组
function Engine:addSkills(skills)
  assert(type(skills) == "table")
  for _, skill in ipairs(skills) do
    self:addSkill(skill)
  end
end

--- 加载一个武将到Engine中。
---
--- 如果武将的trueName和name不同的话，那么也会将其加到同将清单中。
---@param general General @ 要添加的武将
function Engine:addGeneral(general)
  assert(general:isInstanceOf(General))
  if self.generals[general.name] ~= nil then
    error(string.format("Duplicate general %s detected", general.name))
  end
  self.generals[general.name] = general

  if general.kingdom ~= "unknown" then
    table.insertIfNeed(self.kingdoms, general.kingdom)
  end

  if general.name ~= general.trueName then
    local tName = general.trueName
    self.same_generals[tName] = self.same_generals[tName] or { tName }
    table.insert(self.same_generals[tName], general.name)
  end
end

--- 加载一系列武将。
---@param generals General[] @ 要加载的武将列表
function Engine:addGenerals(generals)
  assert(type(generals) == "table")
  for _, general in ipairs(generals) do
    self:addGeneral(general)
  end
end

--- 根据武将名称，获取它的同名武将。
---
--- 注意以此法返回的同名武将列表不包含他自己。
---@param name string @ 要查询的武将名字
---@return string[] @ 这个武将对应的同名武将列表
function Engine:getSameGenerals(name)
  local tmp = name:split("__")
  local tName = tmp[#tmp]
  local ret = self.same_generals[tName] or {}
  return table.filter(ret, function(g)
    return g ~= name and self.generals[g] ~= nil and
      not table.contains(self.disabled_packs, self.generals[g].package.name) and
      not table.contains(self.disabled_generals, g)
  end)
end

local cardId = 1
local _card_name_table = {}

--- 向Engine中加载一张卡牌。
---
--- 卡牌在加载的时候，会被赋予一个唯一的id。（从1开始）
---@param card Card @ 要加载的卡牌
function Engine:addCard(card)
  assert(card.class:isSubclassOf(Card))
  card.id = cardId
  cardId = cardId + 1
  table.insert(self.cards, card)
  if _card_name_table[card.name] == nil then
    _card_name_table[card.name] = card
  end
end

--- 向Engine中加载一系列卡牌。
---@param cards Card[] @ 要加载的卡牌列表
function Engine:addCards(cards)
  for _, card in ipairs(cards) do
    self:addCard(card)
  end
end

--- 根据牌名、花色、点数，复制一张牌。
---
--- 返回的牌是一张虚拟牌。
---@param name string @ 牌名
---@param suit Suit @ 花色
---@param number integer @ 点数
---@return Card
function Engine:cloneCard(name, suit, number)
  local cd = _card_name_table[name]
  assert(cd, "Attempt to clone a card that not added to engine")
  local ret = cd:clone(suit, number)
  ret.package = cd.package
  return ret
end

--- 向Engine中添加一系列游戏模式。
---@param game_modes GameMode[] @ 要添加的游戏模式列表
function Engine:addGameModes(game_modes)
  for _, s in ipairs(game_modes) do
    self:addGameMode(s)
  end
end

--- 向Engine中添加一个游戏模式。
---@param game_mode GameMode @ 要添加的游戏模式
function Engine:addGameMode(game_mode)
  assert(game_mode:isInstanceOf(GameMode))
  if self.game_modes[game_mode.name] ~= nil then
    error(string.format("Duplicate game_mode %s detected", game_mode.name))
  end
  self.game_modes[game_mode.name] = game_mode
end

--- 从已经开启的拓展包中，随机选出若干名武将。
---
--- 对于同名武将不会重复选取。
---
--- 如果符合条件的武将不够，那么就不能保证能选出那么多武将。
---@param num integer @ 要选出的武将数量
---@param generalPool General[] | nil @ 选择的范围，默认是已经启用的所有武将
---@param except string[] | nil @ 特别要排除掉的武将名列表，默认是空表
---@param filter fun(g: General): boolean | nil @ 可选参数，若这个函数返回true的话这个武将被排除在外
---@return General[] @ 随机选出的武将列表
function Engine:getGeneralsRandomly(num, generalPool, except, filter)
  if filter then
    assert(type(filter) == "function")
  end

  generalPool = generalPool or self:getAllGenerals()
  except = except or {}
  for _, g in ipairs(self.packages["test_p_0"].generals) do
    table.insert(except, g.name)
  end

  local availableGenerals = {}
  for _, general in pairs(generalPool) do
    if not table.contains(except, general.name) and not (filter and filter(general)) then
      if (not general.hidden and not general.total_hidden) and
        #table.filter(availableGenerals, function(g)
        return g.trueName == general.trueName
      end) == 0 then
        table.insert(availableGenerals, general)
      end
    end
  end

  if #availableGenerals == 0 then
    return {}
  end

  local result = {}
  for i = 1, num do
    local randomGeneral = math.random(1, #availableGenerals)
    table.insert(result, availableGenerals[randomGeneral])
    table.remove(availableGenerals, randomGeneral)

    if #availableGenerals == 0 then
      break
    end
  end

  return result
end

--- 获取已经启用的所有武将的列表。
---@param except General[] | nil @ 特别指明要排除在外的武将
---@return General[] @ 所有武将的列表
function Engine:getAllGenerals(except)
  local result = {}
  for _, general in pairs(self.generals) do
    if not (except and table.contains(except, general)) then
      if not table.contains(self.disabled_packs, general.package.name) and not table.contains(self.disabled_generals, general.name) then
        table.insert(result, general)
      end
    end
  end

  return result
end

--- 获取当前已经启用的所有卡牌。
---@param except integer[] | nil @ 特别指定要排除在外的id列表
---@return integer[] @ 所有卡牌id的列表
function Engine:getAllCardIds(except)
  local result = {}
  for _, card in ipairs(self.cards) do
    if not (except and table.contains(except, card.id)) then
      if not table.contains(self.disabled_packs, card.package.name) then
        table.insert(result, card.id)
      end
    end
  end

  return result
end

local filtered_cards = {}

--- 根据id返回相应的卡牌。
---@param id integer @ 牌的id
---@param ignoreFilter boolean @ 是否要无视掉锁定视为技，直接获得真牌
---@return Card @ 这个id对应的卡牌
function Engine:getCardById(id, ignoreFilter)
  local ret = self.cards[id]
  if not ignoreFilter then
    ret = filtered_cards[id] or self.cards[id]
  end
  return ret
end

--- 对那个id应用锁定视为技，将它变成要被锁定视为的牌。
---@param id integer @ 要处理的id
---@param player Player @ 和这张牌扯上关系的那名玩家
---@param data any @ 随意，目前只用到JudgeStruct，为了影响判定牌
function Engine:filterCard(id, player, data)
  local card = self:getCardById(id, true)
  if player == nil then
    filtered_cards[id] = nil
    return
  end
  local skills = player:getAllSkills()
  local filters = self:currentRoom().status_skills[FilterSkill] or {}

  if #filters == 0 then
    filtered_cards[id] = nil
    return
  end

  local modify = false
  if data and type(data) == "table" and data.card
    and type(data.card) == "table" and data.card:isInstanceOf(Card) then
    modify = true
  end

  for _, f in ipairs(filters) do
    if f:cardFilter(card, player) then
      local _card = f:viewAs(card, player)
      _card.id = id
      _card.skillName = f.name
      if modify and RoomInstance then
        if not f.mute then
          RoomInstance:broadcastSkillInvoke(f.name)
        end
        RoomInstance:doAnimate("InvokeSkill", {
          name = f.name,
          player = player.id,
          skill_type = f.anim_type,
        })
        RoomInstance:sendLog{
          type = "#FilterCard",
          arg = f.name,
          from = player.id,
          arg2 = card:toLogString(),
          arg3 = _card:toLogString(),
        }
      end
      card = _card
    end
    if card == nil then
      card = self:getCardById(id)
    end
    filtered_cards[id] = card
  end

  if modify then
    filtered_cards[id] = nil
    data.card = card
    return
  end
end

--- 获知当前的Engine是跑在服务端还是客户端，并返回相应的实例。
---@return Room | Client
function Engine:currentRoom()
  if RoomInstance then
    return RoomInstance
  end
  return ClientInstance
end

--- 根据字符串获得这个技能或者这张牌的描述
---
--- 其实就是翻译了 ":" .. name 罢了
---@param name string @ 要获得描述的名字
---@return string @ 描述
function Engine:getDescription(name)
  return self:translate(":" .. name)
end

return Engine
