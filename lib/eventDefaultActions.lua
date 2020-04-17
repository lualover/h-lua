hevent_default_actions = {
    player = {
        esc = cj.Condition(function()
            hevent.triggerEvent(
                cj.GetTriggerPlayer(),
                CONST_EVENT.esc,
                {
                    triggerPlayer = cj.GetTriggerPlayer()
                }
            )
        end),
    },
    unit = {
        attackDetect = cj.Condition(function()
            hevent.triggerEvent(
                cj.GetTriggerUnit(),
                CONST_EVENT.attackDetect,
                {
                    triggerUnit = cj.GetTriggerUnit(),
                    targetUnit = cj.GetEventTargetUnit()
                }
            )
        end),
        attackGetTarget = cj.Condition(function()
            hevent.triggerEvent(
                cj.GetTriggerUnit(),
                CONST_EVENT.attackGetTarget,
                {
                    triggerUnit = cj.GetTriggerUnit(),
                    targetUnit = cj.GetEventTargetUnit()
                }
            )
        end),
        beAttackReady = cj.Condition(function()
            hevent.triggerEvent(
                cj.GetTriggerUnit(),
                CONST_EVENT.beAttackReady,
                {
                    triggerUnit = cj.GetTriggerUnit(),
                    targetUnit = cj.GetAttacker(),
                    attacker = cj.GetAttacker()
                }
            )
        end),
        skillStudy = cj.Condition(function()
            hevent.triggerEvent(
                cj.GetTriggerUnit(),
                CONST_EVENT.skillStudy,
                {
                    triggerUnit = cj.GetTriggerUnit(),
                    triggerSkill = cj.GetLearnedSkill()
                }
            )
        end),
        skillReady = cj.Condition(function()
            hevent.triggerEvent(
                cj.GetTriggerUnit(),
                CONST_EVENT.skillReady,
                {
                    triggerUnit = cj.GetTriggerUnit(),
                    triggerSkill = cj.GetSpellAbilityId(),
                    targetUnit = cj.GetSpellTargetUnit(),
                    targetLoc = cj.GetSpellTargetLoc()
                }
            )
        end),
        skillCast = cj.Condition(function()
            hevent.triggerEvent(
                cj.GetTriggerUnit(),
                CONST_EVENT.skillCast,
                {
                    triggerUnit = cj.GetTriggerUnit(),
                    triggerSkill = cj.GetSpellAbilityId(),
                    targetUnit = cj.GetSpellTargetUnit(),
                    targetLoc = cj.GetSpellTargetLoc()
                }
            )
        end),
        skillStop = cj.Condition(function()
            hevent.triggerEvent(
                cj.GetTriggerUnit(),
                CONST_EVENT.skillStop,
                {
                    triggerUnit = cj.GetTriggerUnit(),
                    triggerSkill = cj.GetSpellAbilityId()
                }
            )
        end),
        skillEffect = cj.Condition(function()
            hevent.triggerEvent(
                cj.GetTriggerUnit(),
                CONST_EVENT.skillEffect,
                {
                    triggerUnit = cj.GetTriggerUnit(),
                    triggerSkill = cj.GetSpellAbilityId(),
                    targetUnit = cj.GetSpellTargetUnit(),
                    targetLoc = cj.GetSpellTargetLoc()
                }
            )
        end),
        skillFinish = cj.Condition(function()
            hevent.triggerEvent(
                cj.GetTriggerUnit(),
                CONST_EVENT.skillFinish,
                {
                    triggerUnit = cj.GetTriggerUnit(),
                    triggerSkill = cj.GetSpellAbilityId()
                }
            )
        end),
        summon = cj.Condition(function()
            hevent.triggerEvent(
                cj.GetTriggerUnit(),
                CONST_EVENT.summon,
                {
                    triggerUnit = cj.GetTriggerUnit(),
                }
            )
        end),
        damaged = cj.Condition(function()
            local sourceUnit = cj.GetEventDamageSource()
            local targetUnit = cj.GetTriggerUnit()
            local damage = cj.GetEventDamage()
            local oldLife = hunit.getCurLife(targetUnit)
            if (damage > 0.125) then
                hattr.set(targetUnit, 0, { life = "+" .. damage })
                htime.setTimeout(
                    0,
                    function(t)
                        htime.delTimer(t)
                        hattr.set(targetUnit, 0, { life = "-" .. damage })
                        hunit.setCurLife(targetUnit, oldLife)
                        hskill.damage(
                            {
                                sourceUnit = sourceUnit,
                                targetUnit = targetUnit,
                                damage = damage,
                                damageKind = "attack"
                            }
                        )
                    end
                )
            end
        end),
        death = cj.Condition(function()
            local u = cj.GetTriggerUnit()
            local killer = hevent.getLastDamageUnit(u)
            if (killer ~= nil) then
                hplayer.addKill(cj.GetOwningPlayer(killer), 1)
            end
            -- @触发死亡事件
            hevent.triggerEvent(
                u,
                CONST_EVENT.dead,
                {
                    triggerUnit = u,
                    killer = killer
                }
            )
            -- @触发击杀事件
            hevent.triggerEvent(
                killer,
                CONST_EVENT.kill,
                {
                    triggerUnit = killer,
                    killer = killer,
                    targetUnit = u
                }
            )
        end),
    },
    rect = {
        enterUnitRange = cj.Condition(function()

        end)
    },
    item = {
        pickup = cj.Condition(function()
            local it = cj.GetManipulatedItem()
            local itId = string.id2char(cj.GetItemTypeId(it))
            if (hslk_global.itemsKV[itId] == nil) then
                -- 排除掉没有注册的物品。例如框架内自带的一些物品
                return
            end
            if (hRuntime.item[it] ~= nil and hRuntime.item[it].positionType == hitem.POSITION_TYPE.UNIT) then
                -- 排除掉runtime内已创建给unit的物品
                return
            end
            local u = cj.GetTriggerUnit()
            local charges = cj.GetItemCharges(it)
            local shadowItId = hitem.getShadowId(itId)
            if (shadowItId == nil) then
                if (hitem.getIsPowerUp(itId) == true) then
                    --检测是否有回调动作
                    local call = hitem.getTriggerCall(itId)
                    if (call ~= nil and type(call) == "function") then
                        call(u, it, itId, charges)
                    end
                    --触发使用物品事件
                    hevent.triggerEvent(
                        u,
                        CONST_EVENT.itemUsed,
                        {
                            triggerUnit = u,
                            triggerItem = it
                        }
                    )
                else
                    --这里删除重建是为了实现地上物品的过期重置
                    hitem.del(it, 0)
                    hitem.create(
                        {
                            itemId = itId,
                            whichUnit = u,
                            charges = charges,
                            during = 0
                        }
                    )
                end
            else
                --注意，系统内此处先获得了face物品，此物品100%是PowerUp的
                --这里删除重建是为了实现地上物品的过期重置
                hitem.del(it, 0)
                --这里是实现神符满格的关键
                hitem.create(
                    {
                        itemId = shadowItId,
                        whichUnit = u,
                        charges = charges,
                        during = 0
                    }
                )
            end
        end),
        drop = cj.Condition(function()
            local u = cj.GetTriggerUnit()
            local it = cj.GetManipulatedItem()
            local itId = string.id2char(cj.GetItemTypeId(it))
            local faceId = hitem.getFaceId(itId)
            local orderId = cj.OrderId("dropitem")
            local charges = cj.GetItemCharges(it)
            if (cj.GetUnitCurrentOrder(u) == orderId) then
                if (hRuntime.item[it] ~= nil) then
                    if (faceId ~= nil) then
                        htime.setTimeout(
                            0,
                            function(t)
                                htime.delTimer(t)
                                local x = cj.GetItemX(it)
                                local y = cj.GetItemX(it)
                                hitem.del(it, 0)
                                --这里是实现表面物品的关键
                                hitem.create(
                                    {
                                        itemId = faceId,
                                        x = x,
                                        y = y,
                                        charges = charges,
                                        during = 0
                                    }
                                )
                            end
                        )
                    else
                        hitem.setPositionType(it, hitem.POSITION_TYPE.COORDINATE)
                    end
                end
                hitem.subAttribute(u, itId, charges)
            end
        end),
        pawn = cj.Condition(function()
            --[[
                抵押物品的原理，首先默认是设定：物品售卖为50%，也就是地图的默认设置
                根据玩家的sellRatio，额外的减少或增加玩家的收入
                从而实现玩家的售卖率提升，至于物品的价格是根据slk获取
                所以如果无法获取slk的属性时，此方法自动无效
            ]]
            local u = cj.GetTriggerUnit()
            local it = cj.GetSoldItem()
            local goldcost = hitem.getGoldCost(it)
            local lumbercost = hitem.getLumberCost(it)
            hRuntime.clear(it)
            if (goldcost ~= 0 or lumbercost ~= 0) then
                local p = cj.GetOwningPlayer(u)
                local sellRatio = hplayer.getSellRatio(u)
                if (sellRatio ~= 50) then
                    if (sellRatio < 0) then
                        sellRatio = 0
                    elseif (sellRatio > 1000) then
                        sellRatio = 1000
                    end
                    local tempRatio = sellRatio - 50.0
                    local tempGold = math.floor(goldcost * tempRatio * 0.01)
                    local tempLumber = math.floor(lumbercost * tempRatio * 0.01)
                    if (goldcost ~= 0 and tempGold ~= 0) then
                        hplayer.addGold(p, tempGold)
                    end
                    if (lumbercost ~= 0 and tempLumber ~= 0) then
                        hplayer.addLumber(p, tempLumber)
                    end
                end
            end
        end),
        use = cj.Condition(function()
            local u = cj.GetTriggerUnit()
            local it = cj.GetManipulatedItem()
            local itId = cj.GetItemTypeId(it)
            local perishable = hitem.getIsPerishable(itId)
            --检测是否使用后自动消失，如果不是，次数补回1
            if (perishable == false) then
                hitem.setCharges(it, hitem.getCharges(it) + 1)
            end
            --检测是否有回调动作
            local call = hitem.getTriggerCall(itId)
            if (call ~= nil and type(call) == "function") then
                call(u, it, itId, charges)
            end
            --触发使用物品事件
            hevent.triggerEvent(
                u,
                CONST_EVENT.itemUsed,
                {
                    triggerUnit = u,
                    triggerItem = it
                }
            )
            --消失的清理cache
            if (perishable == true and hitem.getCharges(it) <= 0) then
                hitem.del(it)
            end
        end),
        destroy = cj.Condition(function()
            hevent.triggerEvent(
                cj.GetManipulatedItem(),
                CONST_EVENT.itemDestroy,
                {
                    triggerItem = cj.GetManipulatedItem(),
                    triggerUnit = cj.GetKillingUnit()
                }
            )
        end),
        separate = cj.Condition(function()
            local u = cj.GetTriggerUnit()
            local it = cj.GetManipulatedItem()
            if (it ~= nil and cj.GetSpellAbilityId() == hitem.DEFAULT_SKILL_ITEM_SEPARATE) then
                print_err("拆分物品尚未完成")
            end
        end),
    }
}