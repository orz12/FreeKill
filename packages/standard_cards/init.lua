-- SPDX-License-Identifier: GPL-3.0-or-later

local extension = Package:new("standard_cards", Package.CardPack)
extension.metadata = require "packages.standard_cards.metadata"

local global_on_use = function(self, room, cardUseEvent)
  if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
    cardUseEvent.tos = {}
    for _, player in ipairs(room:getAlivePlayers()) do
      if not room:getPlayerById(cardUseEvent.from):isProhibited(player, cardUseEvent.card) then
        TargetGroup:pushTargets(cardUseEvent.tos, player.id)
      end
    end
  end
end

local aoe_on_use = function(self, room, cardUseEvent)
  if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
    cardUseEvent.tos = {}
    for _, player in ipairs(room:getOtherPlayers(room:getPlayerById(cardUseEvent.from))) do
      if not room:getPlayerById(cardUseEvent.from):isProhibited(player, cardUseEvent.card) then
        TargetGroup:pushTargets(cardUseEvent.tos, player.id)
      end
    end
  end
end

local slashSkill = fk.CreateActiveSkill{
  name = "slash_skill",
  max_phase_use_time = 1,
  target_num = 1,
  can_use = function(self, player, card)
    return
      table.find(Fk:currentRoom().alive_players, function(p)
        return player:usedCardTimes("slash", Player.HistoryPhase) < self:getMaxUseTime(Self, Player.HistoryPhase, card, p)
      end)
  end,
  target_filter = function(self, to_select, selected, _, card)
    if #selected < self:getMaxTargetNum(Self, card) then
      local player = Fk:currentRoom():getPlayerById(to_select)
      return Self ~= player and Self:inMyAttackRange(player, self:getDistanceLimit(Self, card, player))
    end
  end,
  on_effect = function(self, room, effect)
    local to = effect.to
    local from = effect.from

    room:damage({
      from = room:getPlayerById(from),
      to = room:getPlayerById(to),
      card = effect.card,
      damage = 1,
      damageType = fk.NormalDamage,
      skillName = self.name
    })
  end
}
local slash = fk.CreateBasicCard{
  name = "slash",
  number = 7,
  suit = Card.Spade,
  is_damage_card = true,
  skill = slashSkill,
}

extension:addCards({
  slash,
  slash:clone(Card.Spade, 8),
  slash:clone(Card.Spade, 8),
  slash:clone(Card.Spade, 9),
  slash:clone(Card.Spade, 9),
  slash:clone(Card.Spade, 10),
  slash:clone(Card.Spade, 10),

  slash:clone(Card.Club, 2),
  slash:clone(Card.Club, 3),
  slash:clone(Card.Club, 4),
  slash:clone(Card.Club, 5),
  slash:clone(Card.Club, 6),
  slash:clone(Card.Club, 7),
  slash:clone(Card.Club, 8),
  slash:clone(Card.Club, 8),
  slash:clone(Card.Club, 9),
  slash:clone(Card.Club, 9),
  slash:clone(Card.Club, 10),
  slash:clone(Card.Club, 10),
  slash:clone(Card.Club, 11),
  slash:clone(Card.Club, 11),

  slash:clone(Card.Heart, 10),
  slash:clone(Card.Heart, 10),
  slash:clone(Card.Heart, 11),

  slash:clone(Card.Diamond, 6),
  slash:clone(Card.Diamond, 7),
  slash:clone(Card.Diamond, 8),
  slash:clone(Card.Diamond, 9),
  slash:clone(Card.Diamond, 10),
  slash:clone(Card.Diamond, 13),
})

local jinkSkill = fk.CreateActiveSkill{
  name = "jink_skill",
  can_use = function()
    return false
  end,
  on_effect = function(self, room, effect)
    if effect.responseToEvent then
      effect.responseToEvent.isCancellOut = true
    end
  end
}
local jink = fk.CreateBasicCard{
  name = "jink",
  suit = Card.Heart,
  number = 2,
  skill = jinkSkill,
}

extension:addCards({
  jink,
  jink:clone(Card.Heart, 2),
  jink:clone(Card.Heart, 13),

  jink:clone(Card.Diamond, 2),
  jink:clone(Card.Diamond, 2),
  jink:clone(Card.Diamond, 3),
  jink:clone(Card.Diamond, 4),
  jink:clone(Card.Diamond, 5),
  jink:clone(Card.Diamond, 6),
  jink:clone(Card.Diamond, 7),
  jink:clone(Card.Diamond, 8),
  jink:clone(Card.Diamond, 9),
  jink:clone(Card.Diamond, 10),
  jink:clone(Card.Diamond, 11),
  jink:clone(Card.Diamond, 11),
})

local peachSkill = fk.CreateActiveSkill{
  name = "peach_skill",
  can_use = function(self, player)
    return player:isWounded()
  end,
  on_use = function(self, room, use)
    if not use.tos or #TargetGroup:getRealTargets(use.tos) == 0 then
      use.tos = { { use.from } }
    end
  end,
  on_effect = function(self, room, effect)
    local to = effect.to
    local from = effect.from

    room:recover({
      who = room:getPlayerById(to),
      num = 1,
      card = effect.card,
      recoverBy = room:getPlayerById(from),
      skillName = self.name
    })
  end
}
local peach = fk.CreateBasicCard{
  name = "peach",
  suit = Card.Heart,
  number = 3,
  skill = peachSkill,
}

extension:addCards({
  peach,
  peach:clone(Card.Heart, 4),
  peach:clone(Card.Heart, 6),
  peach:clone(Card.Heart, 7),
  peach:clone(Card.Heart, 8),
  peach:clone(Card.Heart, 9),
  peach:clone(Card.Heart, 12),
  peach:clone(Card.Heart, 12),
})

local dismantlementSkill = fk.CreateActiveSkill{
  name = "dismantlement_skill",
  target_num = 1,
  target_filter = function(self, to_select, selected)
    if #selected < self:getMaxTargetNum(Self) then
      local player = Fk:currentRoom():getPlayerById(to_select)
      return Self ~= player and not player:isAllNude()
    end
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    if to:isAllNude() then return end
    local from = room:getPlayerById(effect.from)
    local cid = room:askForCardChosen(
      from,
      to,
      "hej",
      self.name
    )

    room:throwCard(cid, self.name, to, from)
  end
}
local dismantlement = fk.CreateTrickCard{
  name = "dismantlement",
  suit = Card.Spade,
  number = 3,
  skill = dismantlementSkill,
}

extension:addCards({
  dismantlement,
  dismantlement:clone(Card.Spade, 4),
  dismantlement:clone(Card.Spade, 12),

  dismantlement:clone(Card.Club, 3),
  dismantlement:clone(Card.Club, 4),

  dismantlement:clone(Card.Heart, 12),
})

local snatchSkill = fk.CreateActiveSkill{
  name = "snatch_skill",
  distance_limit = 1,
  target_filter = function(self, to_select, selected, _, card)
    if #selected == 0 then
      local player = Fk:currentRoom():getPlayerById(to_select)
      return
        Self ~= player and
        Self:distanceTo(player) <= self:getDistanceLimit(Self, card, player) and -- for no distance limit for snatch
        not player:isAllNude()
    end
  end,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    local from = effect.from
    if to:isAllNude() then return end
    local cid = room:askForCardChosen(
      room:getPlayerById(from),
      to,
      "hej",
      self.name
    )

    room:obtainCard(from, cid)
  end
}
local snatch = fk.CreateTrickCard{
  name = "snatch",
  suit = Card.Spade,
  number = 3,
  skill = snatchSkill,
}

extension:addCards({
  snatch,
  snatch:clone(Card.Spade, 4),
  snatch:clone(Card.Spade, 11),

  snatch:clone(Card.Diamond, 3),
  snatch:clone(Card.Diamond, 4),
})

local duelSkill = fk.CreateActiveSkill{
  name = "duel_skill",
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local player = Fk:currentRoom():getPlayerById(to_select)
      return Self ~= player
    end
  end,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    local from = room:getPlayerById(effect.from)
    local responsers = { to, from }
    local currentTurn = 1
    local currentResponser = to

    while currentResponser:isAlive() do
      local loopTimes = 1
      if effect.fixedResponseTimes then
        local canFix = currentResponser == to
        if effect.fixedAddTimesResponsors then
          canFix = table.contains(effect.fixedAddTimesResponsors, currentResponser.id)
        end

        if canFix then
          if type(effect.fixedResponseTimes) == 'table' then
            loopTimes = effect.fixedResponseTimes["slash"] or 1
          elseif type(effect.fixedResponseTimes) == 'number' then
            loopTimes = effect.fixedResponseTimes
          end
        end
      end

      local cardResponded
      for i = 1, loopTimes do
        cardResponded = room:askForResponse(currentResponser, 'slash', nil, nil, false, nil, effect)
        if cardResponded then
          room:responseCard({
            from = currentResponser.id,
            card = cardResponded,
            responseToEvent = effect,
          })
        else
          break
        end
      end

      if not cardResponded then
        break
      end

      currentTurn = currentTurn % 2 + 1
      currentResponser = responsers[currentTurn]
    end

    if currentResponser:isAlive() then
      room:damage({
        from = responsers[currentTurn % 2 + 1],
        to = currentResponser,
        card = effect.card,
        damage = 1,
        damageType = fk.NormalDamage,
        skillName = self.name,
      })
    end
  end
}
local duel = fk.CreateTrickCard{
  name = "duel",
  suit = Card.Spade,
  number = 1,
  is_damage_card = true,
  skill = duelSkill,
}

extension:addCards({
  duel,

  duel:clone(Card.Club, 1),

  duel:clone(Card.Diamond, 1),
})

local collateralSkill = fk.CreateActiveSkill{
  name = "collateral_skill",
  target_filter = function(self, to_select, selected)
    local player = Fk:currentRoom():getPlayerById(to_select)
    if #selected == 0 then
      return Self ~= player and player:getEquipment(Card.SubtypeWeapon)
    elseif #selected == 1 then
      return Fk:currentRoom():getPlayerById(selected[1]):inMyAttackRange(player)
    end
  end,
  target_num = 2,
  on_use = function(self, room, cardUseEvent)
    cardUseEvent.tos = { { cardUseEvent.tos[1][1], cardUseEvent.tos[2][1] } }
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    if not to:getEquipment(Card.SubtypeWeapon) then return end
    local use = room:askForUseCard(to, "slash", nil, nil, nil,
                                   { must_targets = effect.subTargets }, effect)

    if use then
      room:useCard(use)
    else
      room:obtainCard(effect.from,
        room:getPlayerById(effect.to):getEquipment(Card.SubtypeWeapon),
        true, fk.ReasonGive)
    end
  end
}
local collateral = fk.CreateTrickCard{
  name = "collateral",
  suit = Card.Club,
  number = 12,
  skill = collateralSkill,
}

extension:addCards({
  collateral,
  collateral:clone(Card.Club, 13),
})

local exNihiloSkill = fk.CreateActiveSkill{
  name = "ex_nihilo_skill",
  on_use = function(self, room, cardUseEvent)
    if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
      cardUseEvent.tos = { { cardUseEvent.from } }
    end
  end,
  on_effect = function(self, room, cardEffectEvent)
    room:drawCards(room:getPlayerById(cardEffectEvent.to), 2, "ex_nihilo")
  end
}
local exNihilo = fk.CreateTrickCard{
  name = "ex_nihilo",
  suit = Card.Heart,
  number = 7,
  skill = exNihiloSkill,
}

extension:addCards({
  exNihilo,
  exNihilo:clone(Card.Heart, 8),
  exNihilo:clone(Card.Heart, 9),
  exNihilo:clone(Card.Heart, 11),
})

local nullificationSkill = fk.CreateActiveSkill{
  name = "nullification_skill",
  can_use = function()
    return false
  end,
  on_effect = function(self, room, effect)
    if effect.responseToEvent then
      effect.responseToEvent.isCancellOut = true
    end
  end
}
local nullification = fk.CreateTrickCard{
  name = "nullification",
  suit = Card.Spade,
  number = 11,
  skill = nullificationSkill,
}

extension:addCards({
  nullification,

  nullification:clone(Card.Club, 12),
  nullification:clone(Card.Club, 13),

  nullification:clone(Card.Diamond, 12),
})

local savageAssaultSkill = fk.CreateActiveSkill{
  name = "savage_assault_skill",
  on_use = aoe_on_use,
  on_effect = function(self, room, effect)
    local cardResponded = room:askForResponse(room:getPlayerById(effect.to), 'slash', nil, nil, false, nil, effect)

    if cardResponded then
      room:responseCard({
        from = effect.to,
        card = cardResponded,
        responseToEvent = effect,
      })
    else
      room:damage({
        from = room:getPlayerById(effect.from),
        to = room:getPlayerById(effect.to),
        card = effect.card,
        damage = 1,
        damageType = fk.NormalDamage,
        skillName = self.name,
      })
    end
  end
}
local savageAssault = fk.CreateTrickCard{
  name = "savage_assault",
  suit = Card.Spade,
  number = 7,
  is_damage_card = true,
  skill = savageAssaultSkill,
}

extension:addCards({
  savageAssault,
  savageAssault:clone(Card.Spade, 13),
  savageAssault:clone(Card.Club, 7),
})

local archeryAttackSkill = fk.CreateActiveSkill{
  name = "archery_attack_skill",
  on_use = aoe_on_use,
  on_effect = function(self, room, effect)
    local cardResponded = room:askForResponse(room:getPlayerById(effect.to), 'jink', nil, nil, false, nil, effect)

    if cardResponded then
      room:responseCard({
        from = effect.to,
        card = cardResponded,
        responseToEvent = effect,
      })
    else
      room:damage({
        from = room:getPlayerById(effect.from),
        to = room:getPlayerById(effect.to),
        card = effect.card,
        damage = 1,
        damageType = fk.NormalDamage,
        skillName = self.name,
      })
    end
  end
}
local archeryAttack = fk.CreateTrickCard{
  name = "archery_attack",
  suit = Card.Heart,
  number = 1,
  is_damage_card = true,
  skill = archeryAttackSkill,
}

extension:addCards({
  archeryAttack,
})

local godSalvationSkill = fk.CreateActiveSkill{
  name = "god_salvation_skill",
  on_use = global_on_use,
  about_to_effect = function(self, room, effect)
    if not room:getPlayerById(effect.to):isWounded() then
      return true
    end
  end,
  on_effect = function(self, room, effect)
    room:recover({
      who = room:getPlayerById(effect.to),
      num = 1,
      recoverBy = room:getPlayerById(effect.from),
      skillName = self.name,
    })
  end
}
local godSalvation = fk.CreateTrickCard{
  name = "god_salvation",
  suit = Card.Heart,
  number = 1,
  skill = godSalvationSkill,
}

extension:addCards({
  godSalvation,
})

local amazingGraceSkill = fk.CreateActiveSkill{
  name = "amazing_grace_skill",
  on_use = global_on_use,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    if not (effect.extra_data and effect.extra_data.AGFilled) then
      return
    end

    local chosen = room:askForAG(to, effect.extra_data.AGFilled, false, self.name)
    room:takeAG(to, chosen, room.players)
    room:obtainCard(effect.to, chosen, true, fk.ReasonPrey)
    table.removeOne(effect.extra_data.AGFilled, chosen)
  end
}

local amazingGraceAction = fk.CreateTriggerSkill{
  name = "amazing_grace_action",
  global = true,
  priority = { [fk.BeforeCardUseEffect] = 0, [fk.CardUseFinished] = 10 }, -- game rule
  events = { fk.BeforeCardUseEffect, fk.CardUseFinished },
  can_trigger = function(self, event, target, player, data)
    local frameFilled = data.extra_data and data.extra_data.AGFilled
    if event == fk.BeforeCardUseEffect then
      return data.card.trueName == 'amazing_grace' and not frameFilled
    else
      return frameFilled
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    if event == fk.BeforeCardUseEffect then
      local toDisplay = room:getNCards(#TargetGroup:getRealTargets(data.tos))
      room:moveCards({
        ids = toDisplay,
        toArea = Card.Processing,
        moveReason = fk.ReasonPut,
      })

      table.forEach(room.players, function(p)
        room:fillAG(p, toDisplay)
      end)

      data.extra_data = data.extra_data or {}
      data.extra_data.AGFilled = toDisplay
    else
      table.forEach(room.players, function(p)
        room:closeAG(p)
      end)

      if data.extra_data and data.extra_data.AGFilled then
        local toDiscard = table.filter(data.extra_data.AGFilled, function(id)
          return room:getCardArea(id) == Card.Processing
        end)

        if #toDiscard > 0 then
          room:moveCards({
            ids = toDiscard,
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPutIntoDiscardPile,
          })
        end
      end

      data.extra_data.AGFilled = nil
    end
  end,
}
Fk:addSkill(amazingGraceAction)

local amazingGrace = fk.CreateTrickCard{
  name = "amazing_grace",
  suit = Card.Heart,
  number = 3,
  skill = amazingGraceSkill,
}

extension:addCards({
  amazingGrace,
  amazingGrace:clone(Card.Heart, 4),
})

local lightningSkill = fk.CreateActiveSkill{
  name = "lightning_skill",
  can_use = function(self, player)
    return not Self:hasDelayedTrick("lightning")
  end,
  on_use = function(self, room, use)
    if not use.tos or #TargetGroup:getRealTargets(use.tos) == 0 then
      use.tos = { { use.from } }
    end
  end,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    local judge = {
      who = to,
      reason = "lightning",
      pattern = ".|2~9|spade",
    }
    room:judge(judge)
    local result = judge.card
    if result.suit == Card.Spade and result.number >= 2 and result.number <= 9 then
      room:damage{
        to = to,
        damage = 3,
        card = effect.card,
        damageType = fk.ThunderDamage,
        skillName = self.name,
      }

      room:moveCards{
        ids = { effect.cardId },
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonUse
      }
    else
      self:onNullified(room, effect)
    end
  end,
  on_nullified = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    local nextp = to
    repeat
      nextp = nextp:getNextAlive()
      if nextp == to then break end
    until not nextp:hasDelayedTrick("lightning")

    if effect.card:isVirtual() then
      nextp:addVirtualEquip(effect.card)
    end

    room:moveCards{
      ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
      to = nextp.id,
      toArea = Card.PlayerJudge,
      moveReason = fk.ReasonPut
    }
  end,
}
local lightning = fk.CreateDelayedTrickCard{
  name = "lightning",
  suit = Card.Spade,
  number = 1,
  skill = lightningSkill,
}

extension:addCards({
  lightning,
  lightning:clone(Card.Heart, 12),
})

local indulgenceSkill = fk.CreateActiveSkill{
  name = "indulgence_skill",
  target_filter = function(self, to_select, selected)
    if #selected == 0 then
      local player = Fk:currentRoom():getPlayerById(to_select)
      if Self ~= player then
        return not player:hasDelayedTrick("indulgence")
      end
    end
    return false
  end,
  target_num = 1,
  on_effect = function(self, room, effect)
    local to = room:getPlayerById(effect.to)
    local judge = {
      who = to,
      reason = "indulgence",
      pattern = ".|.|spade,club,diamond",
    }
    room:judge(judge)
    local result = judge.card
    if result.suit ~= Card.Heart then
      to:skip(Player.Play)
    end
    self:onNullified(room, effect)
  end,
  on_nullified = function(self, room, effect)
    room:moveCards{
      ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonUse
    }
  end,
}
local indulgence = fk.CreateDelayedTrickCard{
  name = "indulgence",
  suit = Card.Spade,
  number = 6,
  skill = indulgenceSkill,
}

extension:addCards({
  indulgence,
  indulgence:clone(Card.Club, 6),
  indulgence:clone(Card.Heart, 6),
})

local crossbowAudio = fk.CreateTriggerSkill{
  name = "#crossbowAudio",
  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.card.trueName == "slash" and
      player:usedCardTimes("slash") > 1
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/standard_cards/audio/card/crossbow")
    room:setEmotion(player, "./packages/standard_cards/image/anim/crossbow")
  end,
}
local crossbowSkill = fk.CreateTargetModSkill{
  name = "#crossbow_skill",
  attached_equip = "crossbow",
  residue_func = function(self, player, skill, scope)
    if player:hasSkill(self.name) and skill.trueName == "slash_skill"
      and scope == Player.HistoryPhase then
      return 999
    end
  end,
}
crossbowSkill:addRelatedSkill(crossbowAudio)
Fk:addSkill(crossbowSkill)

local crossbow = fk.CreateWeapon{
  name = "crossbow",
  suit = Card.Club,
  number = 1,
  attack_range = 1,
  equip_skill = crossbowSkill,
}

extension:addCards({
  crossbow,
  crossbow:clone(Card.Diamond, 1),
})

fk.MarkArmorNullified = "mark__armor_nullified"

local armorInvalidity = fk.CreateInvaliditySkill {
  name = "armor_invalidity_skill",
  global = true,
  invalidity_func = function(self, from, skill)
    return
      from:getMark(fk.MarkArmorNullified) > 0 and
      from:getEquipment(Card.SubtypeArmor) ~= nil and
      skill.attached_equip == Fk:getCardById(from:getEquipment(Card.SubtypeArmor)).name
  end
}
Fk:addSkill(armorInvalidity)

local qingGangSkill = fk.CreateTriggerSkill{
  name = "#qinggang_sword_skill",
  attached_equip = "qinggang_sword",
  frequency = Skill.Compulsory,
  events = { fk.TargetSpecified },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.card and data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)

    data.extra_data = data.extra_data or {}
    data.extra_data.qinggangNullified = data.extra_data.qinggangNullified or {}
    data.extra_data.qinggangNullified[tostring(data.to)] = (data.extra_data.qinggangNullified[tostring(data.to)] or 0) + 1
  end,

  refresh_events = { fk.CardUseFinished },
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.qinggangNullified
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.qinggangNullified) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
    end

    data.qinggangNullified = nil
  end,
}
Fk:addSkill(qingGangSkill)

local qingGang = fk.CreateWeapon{
  name = "qinggang_sword",
  suit = Card.Spade,
  number = 6,
  attack_range = 2,
  equip_skill = qingGangSkill,
}

extension:addCards({
  qingGang,
})

local iceSwordSkill = fk.CreateTriggerSkill{
  name = "#ice_sword_skill",
  attached_equip = "ice_sword",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and (not data.chain) and
      data.card and data.card.trueName == "slash" and not data.to:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    for i = 1, 2 do
      if to:isNude() then break end
      local card = room:askForCardChosen(player, to, "he", self.name)
      room:throwCard(card, self.name, to, player)
    end
    return true
  end
}
Fk:addSkill(iceSwordSkill)

local iceSword = fk.CreateWeapon{
  name = "ice_sword",
  suit = Card.Spade,
  number = 2,
  attack_range = 2,
  equip_skill = iceSwordSkill,
}

extension:addCards({
  iceSword,
})

local doubleSwordsSkill = fk.CreateTriggerSkill{
  name = "#double_swords_skill",
  attached_equip = "double_swords",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.card and data.card.trueName == "slash" and
      (player.room:getPlayerById(data.to).gender ~= player.gender)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:getPlayerById(data.to)
    local result = room:askForDiscard(to, 1, 1, false, self.name, true)
    if #result == 0 then
      player:drawCards(1, self.name)
    end
  end,
}
Fk:addSkill(doubleSwordsSkill)
local doubleSwords = fk.CreateWeapon{
  name = "double_swords",
  suit = Card.Spade,
  number = 2,
  attack_range = 2,
  equip_skill = doubleSwordsSkill,
}

extension:addCards({
  doubleSwords,
})

local bladeSkill = fk.CreateTriggerSkill{
  name = "#blade_skill",
  attached_equip = "blade",
  events = {fk.CardUseFinished},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return end
    local use = data ---@type CardUseStruct
    if use.card.name == "jink" and use.toCard and use.toCard.trueName == "slash" then
      local effect = use.responseToEvent
      return effect.from == player.id
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local use = room:askForUseCard(player, "slash", nil, "#blade_slash:" .. target.id,
      true, { must_targets = {target.id} })
    if use then
      use.extraUse = true
      self.cost_data = use
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(self.cost_data)
  end,
}
Fk:addSkill(bladeSkill)
local blade = fk.CreateWeapon{
  name = "blade",
  suit = Card.Spade,
  number = 5,
  attack_range = 3,
  equip_skill = bladeSkill,
}

extension:addCards({
  blade,
})

local spearSkill = fk.CreateViewAsSkill{
  name = "spear_skill",
  attached_equip = "spear",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    if #selected == 2 then return false end
    return Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  view_as = function(self, cards)
    if #cards ~= 2 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c.skillName = "spear"
    c:addSubcards(cards)
    return c
  end,
}
Fk:addSkill(spearSkill)
local spear = fk.CreateWeapon{
  name = "spear",
  suit = Card.Spade,
  number = 12,
  attack_range = 3,
  equip_skill = spearSkill,
}

extension:addCards({
  spear,
})

local axeProhibit = fk.CreateProhibitSkill{
  name = "#axe_prohibit",
  prohibit_discard = function(self, player, card)
    return player:hasSkill(self.name) and card and card.name == "axe" and
      Fk.currentResponseReason == "#axe_skill" and
      Fk:currentRoom():getCardArea(card.id) == Player.Equip
  end,
}
local axeSkill = fk.CreateTriggerSkill{
  name = "#axe_skill",
  attached_equip = "axe",
  events = {fk.CardEffectCancelledOut},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self.name) then return end
    local effect = data ---@type CardEffectEvent
    return effect.card.trueName == "slash" and effect.from == player.id
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ret = room:askForDiscard(player, 2, 2, true, self.name, true)
    if #ret > 0 then return true end
  end,
  on_use = function() return true end,
}
axeSkill:addRelatedSkill(axeProhibit)
Fk:addSkill(axeSkill)
local axe = fk.CreateWeapon{
  name = "axe",
  suit = Card.Diamond,
  number = 5,
  attack_range = 3,
  equip_skill = axeSkill,
}

extension:addCards({
  axe,
})

local halberdAudio = fk.CreateTriggerSkill{
  name = "#halberdAudio",
  refresh_events = {fk.CardUsing},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      data.card.trueName == "slash" and #TargetGroup:getRealTargets(data.tos) > 1
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:broadcastPlaySound("./packages/standard_cards/audio/card/halberd")
    room:setEmotion(player, "./packages/standard_cards/image/anim/halberd")
  end,
}
local halberdSkill = fk.CreateTargetModSkill{
  name = "#halberd_skill",
  attached_equip = "halberd",
  extra_target_func = function(self, player, skill, card)
    if player:hasSkill(self.name) and skill.trueName == "slash_skill"
      and #player:getCardIds(Player.Hand) == 1
      and player:getCardIds(Player.Hand)[1] == card.id then
      return 2
    end
  end,
}
halberdSkill:addRelatedSkill(halberdAudio)
Fk:addSkill(halberdSkill)
local halberd = fk.CreateWeapon{
  name = "halberd",
  suit = Card.Diamond,
  number = 12,
  attack_range = 4,
  equip_skill = halberdSkill,
}

extension:addCards({
  halberd,
})

local kylinBowSkill = fk.CreateTriggerSkill{
  name = "#kylin_bow_skill",
  attached_equip = "kylin_bow",
  events = {fk.DamageCaused},
  can_trigger = function(self, event, target, player, data)
    local ret = target == player and player:hasSkill(self.name) and
      data.card and data.card.trueName == "slash" and (not data.chain)
    if ret then
      ---@type ServerPlayer
      local to = data.to
      return to:getEquipment(Card.SubtypeDefensiveRide) or
        to:getEquipment(Card.SubtypeOffensiveRide)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = data.to
    local ride_tab = {}
    if to:getEquipment(Card.SubtypeDefensiveRide) then
      table.insert(ride_tab, "+1")
    end
    if to:getEquipment(Card.SubtypeOffensiveRide) then
      table.insert(ride_tab, "-1")
    end
    if #ride_tab == 0 then return end
    local choice = room:askForChoice(player, ride_tab, self.name)
    if choice == "+1" then
      room:throwCard(to:getEquipment(Card.SubtypeDefensiveRide), self.name, to, player)
    else
      room:throwCard(to:getEquipment(Card.SubtypeOffensiveRide), self.name, to, player)
    end
  end
}
Fk:addSkill(kylinBowSkill)
local kylinBow = fk.CreateWeapon{
  name = "kylin_bow",
  suit = Card.Heart,
  number = 5,
  attack_range = 5,
  equip_skill = kylinBowSkill,
}

extension:addCards({
  kylinBow,
})

local eightDiagramSkill = fk.CreateTriggerSkill{
  name = "#eight_diagram_skill",
  attached_equip = "eight_diagram",
  events = {fk.AskForCardUse, fk.AskForCardResponse},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none")))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judgeData = {
      who = player,
      reason = self.name,
      pattern = ".|.|heart,diamond",
    }
    room:judge(judgeData)

    if judgeData.card.color == Card.Red then
      if event == fk.AskForCardUse then
        data.result = {
          from = player.id,
          card = Fk:cloneCard('jink'),
        }
        data.result.card.skillName = "eight_diagram"

        if data.eventData then
          data.result.toCard = data.eventData.toCard
          data.result.responseToEvent = data.eventData.responseToEvent
        end
      else
        data.result = Fk:cloneCard('jink')
        data.result.skillName = "eight_diagram"
      end

      return true
    end
  end
}
Fk:addSkill(eightDiagramSkill)
local eightDiagram = fk.CreateArmor{
  name = "eight_diagram",
  suit = Card.Spade,
  number = 2,
  equip_skill = eightDiagramSkill,
}

extension:addCards({
  eightDiagram,
  eightDiagram:clone(Card.Club, 2),
})

local niohShieldSkill = fk.CreateTriggerSkill{
  name = "#nioh_shield_skill",
  attached_equip = "nioh_shield",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    local effect = data ---@type CardEffectEvent
    return player.id == effect.to and player:hasSkill(self.name) and
      effect.card.trueName == "slash" and effect.card.color == Card.Black
  end,
  on_use = function() return true end,
}
Fk:addSkill(niohShieldSkill)
local niohShield = fk.CreateArmor{
  name = "nioh_shield",
  suit = Card.Club,
  number = 2,
  equip_skill = niohShieldSkill,
}

extension:addCards({
  niohShield,
})

local horseSkill = fk.CreateDistanceSkill{
  name = "horse_skill",
  global = true,
  correct_func = function(self, from, to)
    local ret = 0
    if from:getEquipment(Card.SubtypeOffensiveRide) then
      ret = ret - 1
    end
    if to:getEquipment(Card.SubtypeDefensiveRide) then
      ret = ret + 1
    end
    return ret
  end,
}
if not Fk.skills["horse_skill"] then
  Fk:addSkill(horseSkill)
end

local diLu = fk.CreateDefensiveRide{
  name = "dilu",
  suit = Card.Club,
  number = 5,
}

extension:addCards({
  diLu,
})

local jueYing = fk.CreateDefensiveRide{
  name = "jueying",
  suit = Card.Spade,
  number = 5,
}

extension:addCards({
  jueYing,
})

local zhuaHuangFeiDian = fk.CreateDefensiveRide{
  name = "zhuahuangfeidian",
  suit = Card.Heart,
  number = 13,
}

extension:addCards({
  zhuaHuangFeiDian,
})

local chiTu = fk.CreateOffensiveRide{
  name = "chitu",
  suit = Card.Heart,
  number = 5,
}

extension:addCards({
  chiTu,
})

local daYuan = fk.CreateOffensiveRide{
  name = "dayuan",
  suit = Card.Spade,
  number = 13,
}

extension:addCards({
  daYuan,
})

local ziXing = fk.CreateOffensiveRide{
  name = "zixing",
  suit = Card.Diamond,
  number = 13,
}

extension:addCards({
  ziXing,
})

dofile "packages/standard_cards/i18n/init.lua"

return extension
