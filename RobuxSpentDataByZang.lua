-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Configuration
-- This is the unique name for your DataStore.
-- If you change this, you will lose all previous data.
local ROBUX_SPENT_DATASTORE_NAME = "RobuxSpentLeaderboard_V1"

-- Get our DataStore, which is a special type that sorts data for us
local robuxSpentDataStore = DataStoreService:GetOrderedDataStore(ROBUX_SPENT_DATASTORE_NAME)

-- This function runs every time a player joins
local function onPlayerAdded(player)
	-- Create a folder named "leaderstats"
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Create an IntValue named "Robux Spent" inside the folder
	local robuxSpent = Instance.new("IntValue")
	robuxSpent.Name = "Robux Spent"
	robuxSpent.Value = 0
	robuxSpent.Parent = leaderstats

	-- Load the player's saved data from our DataStore
	local success, savedAmount = pcall(function()
		return robuxSpentDataStore:GetAsync(player.UserId)
	end)

	if success and savedAmount ~= nil then
		-- Data is successfully loaded
		robuxSpent.Value = savedAmount
		
		print(tostring(robuxSpent.Value) .. " spent by " .. player.Name)
		
	else
		-- Something went wrong or no data was found, so we'll start them at 0
		warn("Failed to load Robux Spent data for " .. player.Name .. ". Starting at 0.")
	end
end

-- Connect the function to the PlayerAdded event
Players.PlayerAdded:Connect(onPlayerAdded)

-- This function runs every time a player finishes a purchase prompt
local function onPromptPurchaseFinished(player, assetId, isPurchased)
	-- Check if the purchase was successful
	if isPurchased then
		local productInfo = nil
		local success, err = pcall(function()
			-- Find the Robux price of the item they just bought
			productInfo = MarketplaceService:GetProductInfo(assetId, Enum.InfoType.Asset) -- This works for both Game Passes and Developer Products
		end)

		if success and productInfo then
			local robuxAmount = productInfo.PriceInRobux

			-- Find the player's "Robux Spent" stat
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local robuxSpentValue = leaderstats:FindFirstChild("Robux Spent")
				if robuxSpentValue then
					-- Add the purchased amount to their current total
					robuxSpentValue.Value = robuxSpentValue.Value + robuxAmount
					
					print(tostring(robuxSpentValue.Value) .. " spent by " .. player.Name)

					-- Immediately save the new value to the DataStore
					local saveSuccess, saveErr = pcall(function()
						robuxSpentDataStore:SetAsync(player.UserId, robuxSpentValue.Value)
					end)
					if not saveSuccess then
						warn("Failed to save Robux Spent for " .. player.Name .. ": " .. saveErr)
					end
				end
			end
		else
			warn("Failed to get product info for asset ID " .. assetId .. ": " .. (err or "Unknown error"))
		end
	end
end

-- Connect the function to the purchase event
MarketplaceService.PromptPurchaseFinished:Connect(onPromptPurchaseFinished)

-- This function runs when a player leaves the game
local function onPlayerRemoving(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local robuxSpentValue = leaderstats:FindFirstChild("Robux Spent")
		if robuxSpentValue then
			-- Save the final value when they leave
			local saveSuccess, saveErr = pcall(function()
				robuxSpentDataStore:SetAsync(player.UserId, robuxSpentValue.Value)
			end)
			if not saveSuccess then
				warn("Failed to save Robux Spent for " .. player.Name .. " on PlayerRemoving: " .. saveErr)
			end
		end
	end
end

-- Connect the function to the PlayerRemoving event
Players.PlayerRemoving:Connect(onPlayerRemoving)
