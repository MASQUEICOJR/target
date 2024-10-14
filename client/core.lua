-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp", "lib/Tunnel")
local Proxy = module("vrp", "lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("target")
vPLAYER = Tunnel.getInterface("player")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Zones = {}
local Models = {}
local Selected = {}
local Sucess = false
local Dismantleds = 1
local FreezeDismantle = false
local UseCooldown = GetGameTimer()
-----------------------------------------------------------------------------------------------------------------------------------------
-- TARGET:DISMANTLES
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("target:Dismantles")
AddEventHandler("target:Dismantles", function()
	if not FreezeDismantle then
		FreezeDismantle = true
		Dismantleds = math.random(#Dismantle)
		TriggerEvent("NotifyPush", { code = 20, title = "Localização do Desmanche", x = Dismantle[Dismantleds]["x"], y = Dismantle[Dismantleds]["y"], z = Dismantle[Dismantleds]["z"], text = "Você pode me entregar o veículo ou também pode guardar na garagem para você usar por algum tempo.", blipColor = 60 })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TARGET:DISMANTLERESET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("target:DismantleReset")
AddEventHandler("target:DismantleReset", function()
	FreezeDismantle = false

	local Backup = Dismantleds
	repeat
		Dismantleds = math.random(#Dismantle)
	until Backup ~= Dismantleds
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSTART
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	RegisterCommand("+entityTarget", TargetEnable)
	RegisterCommand("-entityTarget", TargetDisable)
	RegisterKeyMapping("+entityTarget", "Interação auricular.", "keyboard", "LMENU")

	AddCircleZone("Dealership01", vec3(-56.94, -1098.77, 26.42), 0.55, {
		name = "Dealership01",
		heading = 0.0
	}, {
		shop = "Santos",
		Distance = 1.5,
		options = {
			{
				event = "pdm:Open",
				label = "Abrir",
				tunnel = "shop"
			}
		}
	})

	AddCircleZone("Dealership02", vec3(1224.78, 2728.01, 38.0), 0.5, {
		name = "Dealership02",
		heading = 0.0
	}, {
		shop = "Sandy",
		Distance = 2.0,
		options = {
			{
				event = "pdm:Open",
				label = "Abrir",
				tunnel = "shop"
			}
		}
	})

	AddCircleZone("CassinoWheel", vec3(988.37, 43.06, 71.3), 0.5, {
		name = "CassinoWheel",
		heading = 0.0
	}, {
		Distance = 1.5,
		options = {
			{
				event = "luckywheel:Target",
				label = "Roda da Fortuna",
				tunnel = "client"
			}
		}
	})

end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TARGETENABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function TargetEnable()
	if LocalPlayer["state"]["Active"] and GetGameTimer() >= UseCooldown and not IsPauseMenuActive() then
		local Ped = PlayerPedId()
		if (not LocalPlayer["state"]["Admin"] and LocalPlayer["state"]["Charizard"]) or LocalPlayer["state"]["Camera"] or LocalPlayer["state"]["Freecam"] or LocalPlayer["state"]["Carry"] or not MumbleIsConnected() or LocalPlayer["state"]["Buttons"] or LocalPlayer["state"]["Commands"] or LocalPlayer["state"]["Handcuff"] or Sucess or IsPedArmed(Ped,6) or IsPedInAnyVehicle(Ped) then
			return
		end

		SendNUIMessage({ Action = "Open" })
		LocalPlayer["state"]:set("Target",true,false)

		UseCooldown = GetGameTimer() + 2500

		while LocalPlayer["state"]["Target"] do
			local hitZone, entCoords, Entity = RayCastGamePlayCamera()

			if hitZone == 1 then
				local Coords = GetEntityCoords(Ped)

				for k, v in pairs(Zones) do
					if Zones[k]:isPointInside(entCoords) then
						if #(Coords - Zones[k]["center"]) <= v["targetoptions"]["Distance"] then
							if v["targetoptions"]["shop"] ~= nil then
								Selected = v["targetoptions"]["shop"]
							end

							SendNUIMessage({ Action = "Valid", data = Zones[k]["targetoptions"]["options"] })

							Sucess = true
							while Sucess do
								local Ped = PlayerPedId()
								local Coords = GetEntityCoords(Ped)
								local _, entCoords = RayCastGamePlayCamera()

								if (IsControlJustReleased(1, 24) or IsDisabledControlJustReleased(1, 24)) then
									SetCursorLocation(0.5, 0.5)
									SetNuiFocus(true, true)
								end

								if not Zones[k]:isPointInside(entCoords) or #(Coords - Zones[k]["center"]) > v["targetoptions"]["Distance"] then
									Sucess = false
								end

								Wait(1)
							end

							SendNUIMessage({ Action = "Left" })
						end
					end
				end

				if GetEntityType(Entity) ~= 0 then
					-- TriggerServerEvent("admin:Doords",GetEntityCoords(Entitys),GetEntityModel(Entitys),GetEntityHeading(Entitys))

					if IsEntityAVehicle(Entity) then
						local Plate = GetVehicleNumberPlateText(Entity)
						if #(Coords - entCoords) <= 1.0 and Plate ~= "PDMSPORT" then
							local Network = nil
							local Combustivel = false
							local vehModel = GetEntityModel(Entity)
							SetEntityAsMissionEntity(Entity, true, true)

							if NetworkGetEntityIsNetworked(Entity) then
								Network = VehToNet(Entity)
							end

							Selected = { Plate, vRP.VehicleModel(Entity), Entity, Network }

							local Menu = {}

							for _, v in pairs(Fuels) do
								if #(Coords - v["Coords"]) <= 2.5 then
									Combustivel = true
									break
								end
							end

							if not Combustivel then
								if GetSelectedPedWeapon(Ped) == 883325847 then
									Selected[5] = true
									Menu[#Menu + 1] = { event = "engine:Supply", label = "Abastecer", tunnel = "client" }
								else
									if GlobalState["Plates"][Plate] then
										if GetVehicleDoorLockStatus(Entity) == 1 then
											for k,Tyre in pairs(Tyres) do
												local Wheel = GetEntityBoneIndexByName(Entity, k)
												if Wheel ~= -1 then
													local CoordsWheel = GetWorldPositionOfEntityBone(Entity, Wheel)
													if #(Coords - CoordsWheel) <= 1.0 then
														Selected[5] = Tyre
														Menu[#Menu + 1] = { event = "inventory:RemoveTyres", label = "Retirar Pneu", tunnel = "client" }
													end
												end
											end

											Menu[#Menu + 1] = { event = "trunkchest:openTrunk", label = "Abrir Porta-Malas", tunnel = "server" }
											Menu[#Menu + 1] = { event = "player:checkTrunk", label = "Checar Porta-Malas", tunnel = "server" }
										end

										Menu[#Menu + 1] = { event = "garages:Key", label = "Criar Chave Cópia", tunnel = "police" }
										Menu[#Menu + 1] = { event = "inventory:ChangePlate", label = "Trocar Placa", tunnel = "server" }
									else
										if Selected[2] == "stockade" then
											Menu[#Menu + 1] = { event = "inventory:Stockade", label = "Vasculhar", tunnel = "server" }
										end

										if Selected[2] == "pounder" or Selected[2] == "pounder2" then
											Menu[#Menu + 1] = { event = "inventory:Pounder", label = "Vasculhar", tunnel = "server" }
										end
									end

									if not IsThisModelABike(vehModel) then
										local Rolling = GetEntityRoll(Entity)
										if Rolling > 75.0 or Rolling < -75.0 then
											Menu[#Menu + 1] = { event = "player:RollVehicle", label = "Desvirar", tunnel = "server" }
										else
											if GetEntityBoneIndexByName(Entity, "boot") ~= -1 then
												local Trunk = GetEntityBoneIndexByName(Entity, "boot")
												local CoordsTrunk = GetWorldPositionOfEntityBone(Entity, Trunk)
												if #(Coords - CoordsTrunk) <= 1.75 then
													if GetVehicleDoorLockStatus(Entity) == 1 then
														Menu[#Menu + 1] = { event = "player:enterTrunk", label = "Entrar no Porta-Malas", tunnel = "client" }
													else
														Menu[#Menu + 1] = { event = "trunkchest:forceTrunk", label = "Forçar Porta-Malas", tunnel = "server" }
													end

													Menu[#Menu + 1] = { event = "inventory:StealTrunk", label = "Arrombar Porta-Malas", tunnel = "client" }
												end
											end
										end
									end

									if LocalPlayer["state"]["Policia"] then
										Menu[#Menu + 1] = { event = "police:Plate", label = "Verificar Placa", tunnel = "police" }
										Menu[#Menu + 1] = { event = "police:Impound", label = "Registrar Veículo", tunnel = "police" }

										if GlobalState["Plates"][Plate] then
											Menu[#Menu + 1] = { event = "police:Arrest", label = "Apreender Veículo", tunnel = "police" }
										end
									else
										if Plate == "DISM"..(1000 + LocalPlayer["state"]["Passport"]) then
											if #(Coords - Dismantle[Dismantleds]) <= 15 then
												Menu[#Menu + 1] = { event = "inventory:Dismantle", label = "Desmanchar", tunnel = "client" }
											end
										end

										if #(Coords - vec3(405.21, -1638.34, 29.28)) <= 15 then
											Menu[#Menu + 1] = { event = "inventory:Tow", label = "Rebocar", tunnel = "client" }
											Menu[#Menu + 1] = { event = "police:ImpoundCheck", label = "Impound", tunnel = "police" }
										end
									end

									Menu[#Menu + 1] = { event = "engine:Vehrify", label = "Verificar", tunnel = "client" }
								end
							else
								Selected[5] = false
								Menu[#Menu + 1] = { event = "engine:Supply", label = "Abastecer", tunnel = "client" }
							end

							SendNUIMessage({ Action = "Valid", data = Menu })

							Sucess = true
							while Sucess do
								local Ped = PlayerPedId()
								local Coords = GetEntityCoords(Ped)
								local _, entCoords, Entity = RayCastGamePlayCamera()

								if (IsControlJustReleased(1, 24) or IsDisabledControlJustReleased(1, 24)) then
									SetCursorLocation(0.5, 0.5)
									SetNuiFocus(true, true)
								end

								if GetEntityType(Entity) == 0 or #(Coords - entCoords) > 1.0 then
									Sucess = false
								end

								Wait(1)
							end

							SendNUIMessage({ Action = "Left" })
						end
					elseif IsPedAPlayer(Entity) then
						if #(Coords - entCoords) <= 2.0 then
							local index = NetworkGetPlayerIndexFromPed(Entity)
							local source = GetPlayerServerId(index)
							local Menu = {}

							Selected = { source }

							if LocalPlayer["state"]["Policia"] then
								Menu[#Menu + 1] = { event = "police:Inspect", label = "Revistar", tunnel = "paramedic" }
								Menu[#Menu + 1] = { event = "police:ArrestItens", label = "Apreender Itens", tunnel = "paramedic" }
								Menu[#Menu + 1] = { event = "autoschool:SeizeCnh", label = "Apreender CNH", tunnel = "paramedic" }
								Menu[#Menu + 1] = { event = "police:prisonClothes", label = "Uniforme Presidiário", tunnel = "police" }
							elseif LocalPlayer["state"]["Paramedico"] then
								if GetEntityHealth(Entity) <= 100 then
									Menu[#Menu + 1] = { event = "paramedic:Revive", label = "Reanimar", tunnel = "paramedic" }
								else
									Menu[#Menu + 1] = { event = "paramedic:Treatment", label = "Tratamento", tunnel = "paramedic" }
									Menu[#Menu + 1] = { event = "paramedic:Reposed", label = "Colocar de Repouso", tunnel = "paramedic" }
									Menu[#Menu + 1] = { event = "paramedic:Bandage", label = "Passar Ataduras", tunnel = "paramedic" }
									Menu[#Menu + 1] = { event = "paramedic:presetBurn", label = "Roupa de Queimadura", tunnel = "paramedic" }
									Menu[#Menu + 1] = { event = "paramedic:presetPlaster", label = "Colocar Gesso", tunnel = "paramedic" }
									Menu[#Menu + 1] = { event = "paramedic:extractBlood", label = "Extrair Sangue", tunnel = "paramedic" }
								end

								Menu[#Menu + 1] = { event = "paramedic:Diagnostic", label = "Informações", tunnel = "paramedic" }
							end

							if GetEntityHealth(Entity) <= 100 then
								Menu[#Menu + 1] = { event = "police:Inspect", label = "Saquear", tunnel = "paramedic" }
							end

							if IsEntityPlayingAnim(Entity, "random@mugging3", "handsup_standing_base", 3) then
								Menu[#Menu + 1] = { event = "police:Inspect", label = "Revistar", tunnel = "paramedic" }
								Menu[#Menu + 1] = { event = "player:checkShoes", label = "Roubar Sapatos", tunnel = "paramedic" }
							end

							if GetEntityHealth(Entity) > 100 then
								Menu[#Menu + 1] = { event = "player:Charge", label = "Cobrança", tunnel = "paramedic" }
								
								local Reputation = vPLAYER.GetReputation(source)
								if Reputation then
									Menu[#Menu + 1] = { event = "player:Like", label = "👍 Curtir ["..parseInt(Reputation[1]).."]", tunnel = "paramedic" }
									Menu[#Menu + 1] = { event = "player:UnLike", label = "👎 Descurtir ["..parseInt(Reputation[2]).."]", tunnel = "paramedic" }
								end
							end

							SendNUIMessage({ Action = "Valid", data = Menu })

							Sucess = true
							while Sucess do
								local Ped = PlayerPedId()
								local Coords = GetEntityCoords(Ped)
								local _, entCoords, Entity = RayCastGamePlayCamera()

								if (IsControlJustReleased(1, 24) or IsDisabledControlJustReleased(1, 24)) then
									SetCursorLocation(0.5, 0.5)
									SetNuiFocus(true, true)
								end

								if GetEntityType(Entity) == 0 or #(Coords - entCoords) > 2.0 then
									Sucess = false
								end

								Wait(1)
							end

							SendNUIMessage({ Action = "Left" })
						end
					else
						for k, v in pairs(Models) do
							if DoesEntityExist(Entity) then
								if k == GetEntityModel(Entity) then
									if #(Coords - entCoords) <= Models[k]["Distance"] then
										local objNet = nil
										if NetworkGetEntityIsNetworked(Entity) then
											objNet = ObjToNet(Entity)
										end

										Selected = { Entity, k, objNet, GetEntityCoords(Entity) }

										SendNUIMessage({ Action = "Valid", data = Models[k]["options"] })

										Sucess = true
										while Sucess do
											local Ped = PlayerPedId()
											local Coords = GetEntityCoords(Ped)
											local _, entCoords, Entity = RayCastGamePlayCamera()

											if (IsControlJustReleased(1, 24) or IsDisabledControlJustReleased(1, 24)) then
												SetCursorLocation(0.5, 0.5)
												SetNuiFocus(true, true)
											end

											if GetEntityType(Entity) == 0 or #(Coords - entCoords) > Models[k]["Distance"] then
												Sucess = false
											end

											Wait(1)
										end

										SendNUIMessage({ Action = "Left" })
									end
								end
							end
						end
					end
				end
			end

			Wait(100)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TARGETDISABLE
-----------------------------------------------------------------------------------------------------------------------------------------
function TargetDisable()
	if Sucess or not LocalPlayer["state"]["Target"] then
		return
	end

	SendNUIMessage({ Action = "Close" })
	LocalPlayer["state"]:set("Target", false, false)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SELECT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Select", function(Data, Callback)
	Sucess = false
	SetNuiFocus(false, false)
	SendNUIMessage({ Action = "Close" })
	LocalPlayer["state"]:set("Target", false, false)

	if Data["tunnel"] == "client" then
		TriggerEvent(Data["event"], Selected)
	elseif Data["tunnel"] == "shop" then
		TriggerEvent(Data["event"], Selected, Data["service"])
	elseif Data["tunnel"] == "entity" then
		TriggerEvent(Data["event"], Selected[1], Data["service"])
	elseif Data["tunnel"] == "products" then
		TriggerEvent(Data["event"], Data["service"])
	elseif Data["tunnel"] == "server" then
		TriggerServerEvent(Data["event"], Selected)
	elseif Data["tunnel"] == "police" then
		TriggerServerEvent(Data["event"], Selected, Data["service"])
	elseif Data["tunnel"] == "paramedic" then
		TriggerServerEvent(Data["event"], Selected[1], Data["service"])
	elseif Data["tunnel"] == "proserver" then
		TriggerServerEvent(Data["event"], Data["service"])
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Close", function(Data, Callback)
	Sucess = false
	SetNuiFocus(false, false)
	SendNUIMessage({ Action = "Close" })
	LocalPlayer["state"]:set("Target", false, false)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEBUG
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("target:Debug")
AddEventHandler("target:Debug", function()
	Sucess = false
	SetNuiFocus(false, false)
	SendNUIMessage({ Action = "Close" })
	LocalPlayer["state"]:set("Target", false, false)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETCOORDSFROMCAM
-----------------------------------------------------------------------------------------------------------------------------------------
function GetCoordsFromCam(Distance, Coords)
	local Rotation = GetGameplayCamRot()
	local Adjuste = vec3((math.pi / 180) * Rotation["x"], (math.pi / 180) * Rotation["y"], (math.pi / 180) * Rotation["z"])
	local Direction = vec3(-math.sin(Adjuste[3]) * math.abs(math.cos(Adjuste[1])), math.cos(Adjuste[3]) * math.abs(math.cos(Adjuste[1])), math.sin(Adjuste[1]))

	return vec3(Coords[1] + Direction[1] * Distance, Coords[2] + Direction[2] * Distance, Coords[3] + Direction[3] * Distance)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RAYCASTGAMEPLAYCAMERA
-----------------------------------------------------------------------------------------------------------------------------------------
function RayCastGamePlayCamera()
	local Ped = PlayerPedId()
	local Cam = GetGameplayCamCoord()
	local Cam2 = GetCoordsFromCam(10.0, Cam)
	local Handle = StartExpensiveSynchronousShapeTestLosProbe(Cam, Cam2, -1, Ped, 4)
	local _, Hit, Coords, _, Entitys = GetShapeTestResult(Handle)

	return Hit, Coords, Entitys
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDCIRCLEZONE
-----------------------------------------------------------------------------------------------------------------------------------------
function AddCircleZone(Name, Center, Radius, Options, Target)
	Zones[Name] = CircleZone:Create(Center, Radius, Options)
	Zones[Name]["targetoptions"] = Target
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMCIRCLEZONE
-----------------------------------------------------------------------------------------------------------------------------------------
function RemCircleZone(Name)
	if Zones[Name] then
		Zones[Name]:destroy()
		Zones[Name] = nil
	end

	if Sucess then
		Sucess = false
		SetNuiFocus(false, false)
		SendNUIMessage({ Action = "Close" })
		LocalPlayer["state"]:set("Target", false, false)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDTARGETMODEL
-----------------------------------------------------------------------------------------------------------------------------------------
function AddTargetModel(Model, Options)
	for _, v in pairs(Model) do
		Models[v] = Options
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LABELTEXT
-----------------------------------------------------------------------------------------------------------------------------------------
function LabelText(Name, Text)
	if Zones[Name] then
		Zones[Name]["targetoptions"]["options"][1]["label"] = Text
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LABELOPTIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function LabelOptions(Name, Text)
	if Zones[Name] then
		Zones[Name]["targetoptions"]["options"] = Text
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDBOXZONE
-----------------------------------------------------------------------------------------------------------------------------------------
function AddBoxZone(Name, Center, Length, Width, Options, Target)
	Zones[Name] = BoxZone:Create(Center, Length, Width, Options)
	Zones[Name]["targetoptions"] = Target
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXPORTS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("LabelText", LabelText)
exports("AddBoxZone", AddBoxZone)
exports("LabelOptions", LabelOptions)
exports("RemCircleZone", RemCircleZone)
exports("AddCircleZone", AddCircleZone)
exports("AddTargetModel", AddTargetModel)