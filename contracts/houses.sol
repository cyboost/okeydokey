pragma solidity ^0.4.19;

contract OkeyDokey {
    /** Get addresses of other contracts. */
    // function getAddress(uint16) public view returns (address);
}

contract Houses {

    /** Admin of this contract. */
    address private admin;

    /** Running count of house ids. Smallest valid house index is 1. */
    uint256 houseId = 0;

    /** Map of house ids to each corresponding house. */
    mapping(uint256 => House) private houses;

    /** Map of addresses to ids of houses it owns. */
    mapping(address => uint256[]) private housesOf;

    /** Map of a grid's id to houses located in that particular grid. */
    mapping(uint256 => uint256[]) private housesInGrid;

    /** Address of OkeyDokey contract. */
    address private okeyDokeyAddress;

    /** Instance of Devices contract. */
    OkeyDokey private okeyDokey;

    /** Structure of a house. */
    struct House {
        uint256 id;

        /* Owner info */
        address host;
        string hostName;
        address[] administrators;
        address[] devices;

        /* House info */
        string houseName;
        string addrFull;
        string addrSummary;
        string addrDirection;
        string description;
        string housePolicy;
        string cancellationPolicy;
        uint8 houseType;
        uint256 numGuest;
        uint256 numBedroom;
        uint256 numBed;
        uint256 numBathroom;
        uint8[] amenities;
        string[] imageHashes;

        /* Price */
        uint256 hourlyRate;
        uint256 dailyRate;
        uint256 utilityFee;
        uint256 cleaningFee;

        /* Location */
        uint256 latitude;
        uint256 longitude;

        /* Logistics */
        bool active;
        bool valid;
    }

    /**
     * Modifier for functions only smart contract owner can run.
     */
    modifier system() {
        /* Verify admin. */
        require(admin == msg.sender);

        _;
    }

    /**
     * Modifier for functions only house host(owner) can run.
     *
     * @param id The id of house being manipulated.
     */
    modifier onlyHost(uint256 id) {
        House memory house = houses[id];   
        require(house.valid);

        /* Verify owner. */
        require(house.host == msg.sender);

        _;
    }

    /**
     * Modifier for functions only designated admins can run.
     *
     * @param id The id of house being manipulated.
     */
    modifier onlyAdmins(uint256 id) {
        House memory house = houses[id];   
        require(house.valid);

        /* Search for admin address. */
        bool found = false;
        address[] memory admins = house.administrators;
        for (uint256 i=0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                found = true;
            }
        }

        require(found);

        _;
    }

    /**
     * Constrctor function.
     *
     * Assign owner.
     *
     */
    function Houses() public {
        admin = msg.sender;
    }

    /**
     * Reinitialize values dependant on other functions.
     *
     * @param _okeyDokeyAddress The address of main application contract.
     * @return success Whether the reinitialization was successful.
     */
    function initializeContracts(address _okeyDokeyAddress) public returns (bool success) {
        require(msg.sender == admin);
        require(_okeyDokeyAddress != 0);
        require(_okeyDokeyAddress != address(this));

        okeyDokeyAddress = _okeyDokeyAddress;
        okeyDokey = OkeyDokey(okeyDokeyAddress);

        return true;
    }

    /**
     * Register and list a new house (1).
     *
     * Divided into three functions because 
     * Solidity limits the number of local variables to 16.
     *
     * @param houseName The name of the house. Also used as the title of listing.
     * @param hostName The name of the host.
     * @param addrFull Full address of the house.
     * @param addrSummary Shortened address of the house.
     * @param addrDirection Instructions on how to find the house.
     * @param description House description, provided by the host.
     * @return success Whether the registration was successful.
     * @return newId Id of the new house. Must be greater than 0 to be considered valid.
     */
    function registerHouse1(string houseName, string hostName, 
        string addrFull, string addrSummary, string addrDirection, 
        string description) public returns (bool success, uint256 newId) {

        success = false;
        newId = 0;

        /* Smallest houseId is 1 */
        houseId += 1;

        House memory house; 

        house.id = houseId;

        /* Owner info */
        house.host = msg.sender;
        house.hostName = hostName;

        /* House info */
        house.houseName = houseName;
        house.addrFull = addrFull;
        house.addrSummary = addrSummary;
        house.addrDirection = addrDirection;
        house.description = description;

        /* Add newly created house to storage. */
        houses[house.id] = house;
        housesOf[msg.sender].push(house.id);

        /* Logistics */
        house.active = false;
        house.valid = false;

        success = true;
        newId = house.id;
    } 

    /**
     * Register and list a new house (2).
     *
     * Divided into three functions because 
     * Solidity limits the number of local variables to 16.
     *
     * @param id The id of the house to continue initializing.
     * @param housePolicy Basic house rules set by the host.
     * @param cancellationPolicy The cancellation policy of the booking.
     * @param houseType The type of the house.
     * @param numGuest The number of guests the house can accomodate.
     * @param numBedroom The number of bedrooms in the house.
     * @param numBed The total number of beds in the house.
     * @param numBathroom The number of bathrooms in the house.
     * @return success Whether the registration was successful.
     * @return newId Id of the new house. Must be greater than 0 to be considered valid.
     */
    function registerHouse2(uint256 id, string housePolicy, string cancellationPolicy, 
        uint8 houseType, uint256 numGuest, uint256 numBedroom, 
        uint256 numBed, uint256 numBathroom) public returns (bool success, uint256 newId) {

        success = false;
        newId = 0;

        House storage house = houses[id];   
        if (house.host != msg.sender) {
            return;
        }

        /* House info */
        house.housePolicy = housePolicy;
        house.cancellationPolicy = cancellationPolicy;
        house.houseType = houseType;
        house.numGuest = numGuest;
        house.numBedroom = numBedroom;
        house.numBed = numBed;
        house.numBathroom = numBathroom;

        /* Logistics */
        house.active = false;
        house.valid = false;

        success = true;
        newId = house.id;
    } 

    /**
     * Register and list a new house (3).
     *
     * Divided into three functions because 
     * Solidity limits the number of local variables to 16.
     *
     * @param id The id of the house to continue initializing.
     * @param hourlyRate The hourly rate of the house.
     * @param dailyRate The daily rate of the house.
     * @param utilityFee The utility fee of the house.
     * @param cleaningFee The cleaning fee of the house.
     * @param latitude The lattitude of the house, multiplied by 1 million.
     * @param longitude The longitude of the house, multiplied by 1 million.
     * @return success Whether the registration was successful.
     * @return newId Id of the new house. Must be greater than 0 to be considered valid.
     */
    function registerHouse3(uint256 id,  
        uint256 hourlyRate, uint256 dailyRate, uint256 utilityFee, uint256 cleaningFee, 
        uint256 latitude, uint256 longitude) public returns (bool success, uint256 newId) {

        success = false;

        bool succ;
        uint256 gridId;
        (succ, gridId) = getGridId(latitude, longitude);
        if (!succ) {
            /* This listing failed. Erase houseId. */
            delete houses[id];
            houseId -= 1;
            return;
        }

        House storage house = houses[id];   
        if (house.host != msg.sender) {
            return;
        }

        /* Price */
        house.hourlyRate = hourlyRate;
        house.dailyRate = dailyRate;
        house.utilityFee = utilityFee;
        house.cleaningFee = cleaningFee;

        /* Location */
        house.latitude = latitude;
        house.longitude = longitude;

        /* Logistics */
        house.active = true;
        house.valid = true;

        /* Add host as administrator. */
        addAdministrator(house.id, msg.sender);

        /* Add newly created house to storage. */
        housesInGrid[gridId].push(house.id);

        success = true;
        newId = house.id;
    } 

    /**
     * Edit a listed house (1).
     *
     * Divided into three functions because 
     * Solidity limits the number of local variables to 16.
     *
     * @param id The id of the house to edit.
     * @param houseName The name of the house. Also used as the title of listing.
     * @param hostName The name of the host.
     * @param addrFull Full address of the house.
     * @param addrSummary Shortened address of the house.
     * @param addrDirection Instructions on how to find the house.
     * @param description House description, provided by the host.
     * @return success Whether the edit was successful.
     */
    function editHouse1(uint256 id, string houseName, string hostName, 
        string addrFull, string addrSummary, string addrDirection, 
        string description) onlyAdmins(id) public returns (bool success) {

        success = false;

        House storage house = houses[id]; 
        if (!house.valid) {
            return;
        } 

        /* Owner info */
        house.hostName = hostName;

        /* House info */
        house.houseName = houseName;
        house.addrFull = addrFull;
        house.addrSummary = addrSummary;
        house.addrDirection = addrDirection;
        house.description = description;

        success = true;
    } 

    /**
     * Edit a listed house (2).
     *
     * Divided into three functions because 
     * Solidity limits the number of local variables to 16.
     *
     * @param id The id of the house to edit.
     * @param housePolicy Basic house rules set by the host.
     * @param cancellationPolicy The cancellation policy of the booking.
     * @param houseType The type of the house.
     * @param numGuest The number of guests the house can accomodate.
     * @param numBedroom The number of bedrooms in the house.
     * @param numBed The total number of beds in the house.
     * @param numBathroom The number of bathrooms in the house.
     * @return success Whether the edit was successful.
     */
    function editHouse2(uint256 id, string housePolicy, string cancellationPolicy, 
        uint8 houseType, uint256 numGuest, uint256 numBedroom, 
        uint256 numBed, uint256 numBathroom) onlyAdmins(id) public returns (bool success) {

        success = false;

        /* Prices */
        bool succ = updateSecondaryInfo(id, housePolicy, cancellationPolicy, 
                                        houseType, numGuest, numBedroom, 
                                        numBed, numBathroom);
        if (!succ) {
            return;
        }

        success = true;
    } 

    /**
     * Update secondary info for a house listing.
     *
     * Helper function for editHouse2. 
     *
     * @param id The id of the house to edit.
     * @param housePolicy Basic house rules set by the host.
     * @param cancellationPolicy The cancellation policy of the booking.
     * @param houseType The type of the house.
     * @param numGuest The number of guests the house can accomodate.
     * @param numBedroom The number of bedrooms in the house.
     * @param numBed The total number of beds in the house.
     * @param numBathroom The number of bathrooms in the house.
     * @return success Whether the update was successful.
     */
    function updateSecondaryInfo(uint256 id, string housePolicy, string cancellationPolicy, 
        uint8 houseType, uint256 numGuest, uint256 numBedroom, 
        uint256 numBed, uint256 numBathroom) internal returns (bool success) {

        House storage house = houses[id];  
        if (!house.valid) {
            return;
        }

        /* House info */
        house.housePolicy = housePolicy;
        house.cancellationPolicy = cancellationPolicy;
        house.houseType = houseType;
        house.numGuest = numGuest;
        house.numBedroom = numBedroom;
        house.numBed = numBed;
        house.numBathroom = numBathroom;

        success = true;
     }

    /**
     * Edit a listed house (3).
     *
     * Divided into three functions because 
     * Solidity limits the number of local variables to 16.
     *
     * @param id The id of the house to edit.
     * @param hourlyRate The hourly rate of the house.
     * @param dailyRate The daily rate of the house.
     * @param utilityFee The utility fee of the house.
     * @param cleaningFee The cleaning fee of the house.
     * @param latitude The lattitude of the house, multiplied by 1 million.
     * @param longitude The longitude of the house, multiplied by 1 million.
     * @return success Whether the edit was successful.
     */
    function editHouse3(uint256 id, uint256 hourlyRate, 
        uint256 dailyRate, uint256 utilityFee, uint256 cleaningFee, 
        uint256 latitude, uint256 longitude) onlyAdmins(id) public returns (bool success) {

        success = false;

        /* Prices */
        bool succ1 = updatePrices(id, hourlyRate, dailyRate, utilityFee, cleaningFee);
        if (!succ1) {
            return;
        }

        /* Coordinates */
        bool succ2 = updateCoordinates(id, latitude, longitude);
        if (!succ2) {
            return;
        }

        success = true;
    } 

    /**
     * Update prices for a house listing.
     *
     * Helper function for editHouse3. 
     * Currently public due to stack size limitations in EVM.
     *
     * @param id The id of the house to edit.
     * @param hourlyRate The hourly rate of the house.
     * @param dailyRate The daily rate of the house.
     * @param utilityFee The utility fee of the house.
     * @param cleaningFee The cleaning fee of the house.
     * @return success Whether the update was successful.
     */
    function updatePrices(uint256 id, uint256 hourlyRate, uint256 dailyRate, 
        uint256 utilityFee, uint256 cleaningFee) internal returns (bool success) {

        House storage house = houses[id];  
        if (!house.valid) {
            return;
        }

        /* Price */
        house.hourlyRate = hourlyRate;
        house.dailyRate = dailyRate;
        house.utilityFee = utilityFee;
        house.cleaningFee = cleaningFee;

        success = true;
     }

    /**
     * Update coordinates for a house listing.
     *
     * Helper function for editHouse3. 
     *
     * @param id The id of the house to edit.
     * @param latitude The lattitude of the house, multiplied by 1 million.
     * @param longitude The longitude of the house, multiplied by 1 million.
     * @return success Whether the update was successful.
     */
    function updateCoordinates(uint256 id, uint256 latitude, uint256 longitude) 
        internal returns (bool success) {

        success = false;

        /* Check new coordinates. */
        bool succ;
        uint256 gridId;
        (succ, gridId) = getGridId(latitude, longitude);
        if (!succ) {
            return;
        }

        /* Fetch previous coordinates. */
        House memory house = houses[id];  
        if (!house.valid) {
            return;
        }

        bool prevSucc;
        uint256 prevGridId;
        (prevSucc, prevGridId) = getGridId(house.latitude, house.longitude);
        if (!prevSucc) {
            return;
        }

        /* Add newly created house to storage. */
        if (prevGridId != gridId) {
            housesInGrid[gridId].push(house.id);
            /* Erase from previous gridId */
            removeFromGridId(prevGridId, house.id);
        }

        /* Update location. */
        house.latitude = latitude;
        house.longitude = longitude;

        success = true;
     }

     /**
     * Remove houseId from grid.
     *
     * Helper function for editHouse3. 
     *
     * @param prevGridId The id of the grid to erase from.
     * @param id The id of the house to erase.
     * @return success Whether the deletion was successful.
     */
    function removeFromGridId(uint256 prevGridId, uint256 id) internal returns (bool success) {
        success = false;
        uint256[] storage ids = housesInGrid[prevGridId];
        uint256 toErase;
        for (uint256 i=0; i < ids.length; i++) {
            if (ids[i] == id) {
                toErase = i;
            }
        } 
        delete ids[toErase];
        success = true;
    }

    /**
     * Fetch house info (1).
     *
     * Divided into three functions because 
     * Solidity limits the number of local variables to 16.
     *
     * @param id The id of the house to query.
     * @return success Whether the query was successful.
     * @return houseName The name of the house. Also used as the title of listing.
     * @return hostName The name of the host.
     * @return addrFull Full address of the house.
     * @return addrSummary Shortened address of the house.
     * @return addrDirection Instructions on how to find the house.
     * @return description House description, provided by the host.
     * @return housePolicy Basic house rules set by the host.
     * @return cancellationPolicy The cancellation policy of the booking.
     * @return houseType The type of the house.
     */
    function getHouseInfo1(uint256 id) public view 
        returns (bool success, string houseName, string hostName,
                 string addrFull, string addrSummary, string addrDirection,
                 string description) {

        success = false;
        
        House memory house = houses[id];   

        if (!house.valid) {
            return;
        }

        /* Owner info */
        hostName = house.hostName;

        /* House info */
        houseName = house.houseName; 
        addrFull = house.addrFull;
        addrSummary = house.addrSummary; 
        addrDirection = house.addrDirection; 
        description = house.description;

        success = true;
    } 

    /**
     * Fetch house info (2).
     *
     * Divided into three functions because 
     * Solidity limits the number of local variables to 16.
     *
     * @param id The id of the house to query.
     * @return success Whether the query was successful.
     * @return description House description, provided by the host.
     * @return housePolicy Basic house rules set by the host.
     * @return cancellationPolicy The cancellation policy of the booking.
     * @return houseType The type of the house.
     * @return numGuest The number of guests the house can accomodate.
     * @return numBedroom The number of bedrooms in the house.
     * @return numBed The total number of beds in the house.
     * @return numBathroom The number of bathrooms in the house.
     */
    function getHouseInfo2(uint256 id) public view 
        returns (bool success, string housePolicy, string cancellationPolicy, 
                 uint8 houseType, uint256 numGuest, uint256 numBedroom, 
                 uint256 numBed, uint256 numBathroom) {

        success = false;
        
        House memory house = houses[id];   

        if (!house.valid) {
            return;
        }

        /* House info */
        housePolicy = house.housePolicy;
        cancellationPolicy = house.cancellationPolicy;
        houseType = house.houseType;
        numGuest = house.numGuest;
        numBedroom = house.numBedroom;
        numBed = house.numBed;
        numBathroom = house.numBathroom;

        success = true;
    } 

    /**
     * Fetch house info (3).
     *
     * Divided into three functions because 
     * Solidity limits the number of local variables to 16.
     *
     * @param id The id of the house to query.
     * @return success Whether the query was successful.
     * @return hourlyRate The hourly rate of the house.
     * @return dailyRate The daily rate of the house.
     * @return utilityFee The utility fee of the house.
     * @return cleaningFee The cleaning fee of the house.
     * @return latitude The lattitude of the house, multiplied by 1 million.
     * @return longitude The longitude of the house, multiplied by 1 million.
     */
    function getHouseInfo3(uint256 id) public view 
        returns (bool success, uint256 hourlyRate, uint256 dailyRate, 
                 uint256 utilityFee, uint256 cleaningFee, 
                 uint256 latitude, uint256 longitude) {

        success = false;
        
        House memory house = houses[id];   

        if (!house.valid) {
            return;
        }

        /* House info */
        hourlyRate = house.hourlyRate; 
        dailyRate = house.dailyRate;
        utilityFee = house.utilityFee; 
        cleaningFee = house.cleaningFee; 
        latitude = house.latitude; 
        longitude = house.longitude;

        success = true;
    } 

    /**
     * Setter for house name.
     *
     * @param id Id of house to edit.
     * @param houseName New name of house.
     * @return success Whether the operation was successful.
     */
    function setHouseName(uint256 id, string houseName) public returns (bool success) {
        success = false;

        House memory house = houses[id];
        if (house.valid) {
            house.houseName = houseName;
            success = true;
            return;
        }
    }

    /**
     * Getter for house name.
     *
     * @param id Id of house to query.
     * @return success Whether the query was successful.
     * @return houseName Name of the house.
     */
    function getHouseName(uint256 id) public view returns (bool success, string houseName) {
        success = false;

        House memory house = houses[id];
        if (house.valid) {
            success = true;
            houseName = house.houseName;
            return;
        }
    }

    /**
     * Setter for host name.
     *
     * @param id Id of house to edit.
     * @param hostName New name of host.
     * @return success Whether the operation was successful.
     */
    function setHostName(uint256 id, string hostName) public returns (bool success) {
        success = false;

        House memory house = houses[id];
        if (house.valid) {
            house.hostName = hostName;
            success = true;
            return;
        }
    }

    /**
     * Getter for host name.
     *
     * @param id Id of house to query.
     * @return success Whether the query was successful.
     * @return hostName Name of the house.
     */
    function getHostName(uint256 id) public view returns (bool success, string hostName) {
        success = false;

        House memory house = houses[id];
        if (house.valid) {
            success = true;
            hostName = house.hostName;
            return;
        }
    }

    /**
     * Add administrator to house.
     *
     * @param id Id of house to edit.
     * @param newAdmin The address of new admin.
     * @return success Whether the operation was successful.
     */
    function addAdministrator(uint256 id, address newAdmin) 
        onlyHost(id) public returns (bool success) {

        success = false;

        House storage house = houses[id];
        if (house.valid) {
            
            bool found = false;
            uint256 index = 0;
            address[] memory admins = house.administrators;

            /* Search for previous entry */
            for (uint256 i=0; i < admins.length; i++) {
                if (admins[i] == newAdmin) {
                    found = true;
                    index = i;
                }
            }

            if (!found) {
                house.administrators.push(newAdmin);
                success = true;
                return;
            }
        }
    }

    /**
     * Remove administrator from house.
     *
     * @param id Id of house to query.
     * @param toDelete The address of admin to delete.
     * @return success Whether the operation was successful.
     */
    function removeAdministrator(uint256 id, address toDelete) 
        onlyHost(id) public returns (bool success) {

        success = false;

        House storage house = houses[id];
        if (house.valid) {

            bool found = false;
            uint256 index = 0;
            address[] memory admins = house.administrators;

            /* Search for previous entry */
            for (uint256 i=0; i < admins.length; i++) {
                if (admins[i] == toDelete) {
                    found = true;
                    index = i;
                }
            }

            if (found) {
                delete admins[index];
                success = true;
                return;
            }
        }
    }

    /**
     * Calculate grid id from coordinates.
     *
     * @param latitude The lattitude of the house, multiplied by 1 million.
     * @param longitude The longitude of the house, multiplied by 1 million.
     * @return success Whether the coordinates were valid.
     * @return gridId Id within the earth's grid.
     */
    function getGridId(uint256 latitude, uint256 longitude) public returns (bool success, uint256 gridId) {
        success = false;

        success = true;
        gridId = 0;
    }

    /**
     * Self destruct.
     */
    function kill() system public { 
        if (msg.sender == admin) selfdestruct(admin); 
    }

}