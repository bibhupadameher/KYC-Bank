pragma solidity ^0.6.1;
pragma experimental ABIEncoderV2;

contract kyc {
    address admin;
    string zero = "0";
    /*
    Struct for a customer
     */
    struct Customer {
        string userName; //unique
        string data_hash; //unique
        uint8 rating;
        uint8 upvotes;
        address bank;
        string password;
    }
    /*
    Struct for a Bank
     */
    struct Bank {
        address ethAddress; //unique
        string bankName;
        uint8 rating;
        uint8 kycCount;
        uint8 upvotes;
        string regNumber; //unique
    }
    /*
    Struct for a KYC Request
     */
    struct KYCRequest {
        string userName;
        string data_hash; //unique
        address bank;
        bool isAllowed;
    }
    /*
    Mapping a customer's username to the Customer struct
     */
    mapping(string => Customer) customers;
    uint8 customerSize = 0;
    /*
    Mapping a final customer's username to the Customer struct
     */
    mapping(string => Customer) finalCustomers;
    /*
    Mapping a bank's address to the Bank Struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(address => Bank) banks;
    uint8 bankSize = 0;
    /*
    Mapping a customer's user name with a bank's address
    This mapping is used to keep track of every upvote given by a bank to a customer
     */
    mapping(string => mapping(address => uint256)) upvotes;
    /*
    Mapping a customer's user name with a bank's address
    This mapping is used to keep track of every rating given by a bank to a customer
     */
    mapping(string => mapping(address => uint256)) customerRatings;
    /*
    Mapping a Bank's address with other bank's address
    This mapping is used to keep track of every rating given by a bank to a customer
     */
    mapping(address => mapping(address => uint256)) bankRatings;
    /*
    Mapping a customer's Data Hash to KYC request captured for that customer.
    This mapping is used to keep track of every kycRequest initiated for every customer by a bank.
     */
    mapping(string => KYCRequest) kycRequests;
    string[] customerDataList;
    /**
     * Constructor of the contract.
     * We save the contract's admin as the account which deployed this contract.
     */
    constructor() public {
        admin = msg.sender;
    }
    /**
     * Record a new KYC request on behalf of a customer
     * The sender of message call is the bank itself
     * @param  {string} _userName The name of the customer for whom KYC is to be done
     * @param  {address} _bankEthAddress The ethAddress of the bank issuing this request
     * @return {bool}        True if this function execution was successful
     */
    function addKycRequest(string memory _userName, string memory _customerData)
        public
        returns (uint8)
    {
        // Check that the user's KYC has not been done before, the Bank is a valid bank and it is allowed to perform KYC.
        require(
            kycRequests[_customerData].bank == address(0),
            "This user already has a KYC request with same data in process."
        );
        //Fetch the rating of Bank and check is  allowed to perform KYC or not , We have used rating * 100 comparison
        uint8 bankRating = banks[msg.sender].rating;
        bool isAllowed = false;
        if (bankRating > 50) {
            isAllowed = true;
        }
        kycRequests[_customerData].data_hash = _customerData;
        kycRequests[_customerData].userName = _userName;
        kycRequests[_customerData].bank = msg.sender;
        kycRequests[_customerData].isAllowed = isAllowed;
        customerDataList.push(_customerData);
        banks[msg.sender].kycCount = banks[msg.sender].kycCount + 1;
        return 1;
    }
    /**
     * Add a new customer
     * @param {string} _userName Name of the customer to be added
     * @param {string} _hash Hash of the customer's ID submitted for KYC
     */
    function addCustomer(string memory _userName, string memory _customerData)
        public
        returns (uint8)
    {
        require(
            customers[_userName].bank == address(0),
            "This customer is already present"
        );
        require(
            kycRequests[_customerData].isAllowed == true,
            "The Bank is not allowed to process requests"
        );
        customers[_userName].userName = _userName;
        customers[_userName].data_hash = _customerData;
        customers[_userName].bank = msg.sender;
        customers[_userName].upvotes = 0;
        customers[_userName].rating = 0;
        customers[_userName].password = "";
        customerSize++;
        return 1;
    }
    /**
     * Remove KYC request
     * @param  {string} _userName Name of the customer
     * @return {uint8}   0 indicates failure, 1 indicates success
     */
    function removeKYCRequest(string memory _userName) public returns (uint8) {
        uint8 returnValue = 0;
        for (uint256 i = 0; i < customerDataList.length; i++) {
            if (
                stringsEquals(
                    kycRequests[customerDataList[i]].userName,
                    _userName
                )
            ) {
                delete kycRequests[customerDataList[i]];
                for (uint256 j = i + 1; j < customerDataList.length; j++) {
                    customerDataList[j - 1] = customerDataList[j];
                }
                //   customerDataList.length --;
                returnValue = 1;
            }
        }
        return returnValue; // 0 is returned if no request with the input username is found.
    }
    /**
     * Remove customer information
     * @param  {string} _userName Name of the customer
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function removeCustomer(string memory _userName) public returns (uint8) {
        if (customers[_userName].bank != address(0)) {
            delete customers[_userName];
            customerSize--;
            return 1;
        } else {
            return 0;
        }
    }
    /**
     * View customer information
     * @param  {public} _userName Name of the customer
     * @param  {public} _password password of the customer
     * @return {Customer}         The customer struct as an object
     */
    function viewCustomer(string memory _userName, string memory _password)
        public
        view
        returns (string memory)
    {
        if (
            stringsEquals(customers[_userName].password, _password) ||
            (stringsEquals(customers[_userName].password, "") &&
                stringsEquals(zero, _password))
        ) {
            return (customers[_userName].data_hash);
        } else {
            return ("The Customer Credentials are not valid");
        }
    }
    /**
     * Upvote to provide ratings on customers
     * @param  {string} _userName Name of the customer
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function upVoteCustomer(string memory _userName) public returns (uint8) {
        require(
            upvotes[_userName][msg.sender] == 0,
            "This Bank has already processed the upvotes for the customer"
        );
        require(
            msg.sender == banks[msg.sender].ethAddress,
            "This Bank is not a valid bank"
        );
        upvotes[_userName][msg.sender] = 1;
        customers[_userName].upvotes = customers[_userName].upvotes + 1;
        uint8 rating = (customers[_userName].upvotes * 100) / bankSize;
        customers[_userName].rating = rating;
        if (customers[_userName].rating > 50) {
            if (finalCustomers[_userName].bank == address(0))
                finalCustomers[_userName] = customers[_userName];
        }
        return 1;
    }
    /**
     * Modify Customer data
     * @param  {string} _userName Name of the customer
     * @param  {string} _password password of the customer
     * @param  {string} data_hash new hash data of the customer
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function modifyCustomerData(
        string memory _userName,
        string memory _password,
        string memory data_hash
    ) public returns (uint8) {
        require(
            customers[_userName].bank != address(0),
            "The Customer data is not vaildated yet"
        );
        if (
            stringsEquals(customers[_userName].password, _password) ||
            (stringsEquals(customers[_userName].password, "") &&
                stringsEquals(zero, _password))
        ) {
            if (finalCustomers[_userName].bank != address(0)) {
                delete finalCustomers[_userName];
            }
            customers[_userName].userName = _userName;
            customers[_userName].data_hash = data_hash;
            customers[_userName].bank = msg.sender;
            customers[_userName].upvotes = 0;
            customers[_userName].rating = 0;
            return 1;
        } else {
            return 0;
        }
    }
    /**
     * Get Bank Requests
     * @param  {address} _bankEthAddresse address of the Bank
     * @return {customer_data[]} the list of customer_data which is present in kycRequests but not validated
     */
    function getBankRequests(address _bankEthAddresse)
        public
        view
        returns (string[] memory)
    {
        string[] memory customer_data;
        uint256 count = 0;
        for (uint256 i = 0; i < customerDataList.length; i++) {
            if (kycRequests[customerDataList[i]].bank == _bankEthAddresse) {
                if (
                    customers[kycRequests[customerDataList[i]].userName].bank ==
                    address(0)
                ) {
                    customer_data[count++] = customerDataList[i];
                }
            }
        }
        return customer_data;
    }
    /**
     * Upvote to provide ratings to Banks
     * @param  {address} _bankEthAddress address of the bank
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function upVoteBank(address _bankEthAddress) public returns (uint8) {
        require(
            bankRatings[_bankEthAddress][msg.sender] == 0,
            "This Bank has already processed the upvotes for the Bank"
        );
        require(
            msg.sender != _bankEthAddress,
            "Bank can not upvote to it self"
        );
         require(
            msg.sender == banks[msg.sender].ethAddress,
            "This Bank is not a valid bank"
        );
        bankRatings[_bankEthAddress][msg.sender] = 1;
        banks[_bankEthAddress].upvotes = banks[_bankEthAddress].upvotes + 1;
        uint8 rating = (banks[_bankEthAddress].upvotes * 100) / bankSize;
        banks[_bankEthAddress].rating = rating;
        return 1;
    }
    /**
     * Get Customer Rating
     * @param  {string} _userName  user name  of the Customer
     * @return {uint8}   rating of Customer
     */
    function getCustomerRating(string memory _userName)
        public
        view
        returns (uint8)
    {
        require(
            customers[_userName].bank != address(0),
            "This user name is not a valid Bank Customer"
        );
        //Divide the rating by 100 in the client app to get the exact rating
        return customers[_userName].rating;
    }
    /**
     * Get Bank Rating
     * @param  {address} _bankEthAddress  address of the bank
     * @return {uint8}   rating of Bank
     */
    function getBankRating(address _bankEthAddress)
        public
        view
        returns (uint8)
    {
        require(
            banks[_bankEthAddress].ethAddress != address(0),
            "This address is not a valid Bank address"
        );
        //Divide the rating by 100 in the client app to get the exact rating
        return banks[_bankEthAddress].rating;
    }
    /**
     * Retrieve access history for a resource
     * @param  {string} _userName  user Name of customer
     * @return {address}    address of the bank
     */
    function retriveAccessHistory(string memory _userName)
        public
        view
        returns (address)
    {
        require(
            customers[_userName].bank != address(0),
            "This user name is not a valid Bank Customer"
        );
        return customers[_userName].bank;

    }

    /**
     * Set Password for Customer
     * @param  {string} _userName user name of the Customer
     * @param  {string} _password Password of the Customer
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function setPassword(string memory _userName, string memory _password)
        public
        returns (uint8)
    {
        if (stringsEquals(customers[_userName].password, "")) {
            customers[_userName].password = _password;
            return 1;
        } else {
            return 0;
        }
    }

    /**
     * Get Bank Details
     * @param  {address} _bankEthAddress address of the bank
     * @return {Bank}   Bank struct of the bank
     */
    function getBankDetails(address _bankEthAddress)
        public view
        returns (Bank memory)
    {
        require(
            banks[_bankEthAddress].ethAddress != address(0),
            "This address is not a valid Bank address"
        );
        return banks[_bankEthAddress];

    }

    /**
     * Add Bank
     * @param  {string} _bankName  name of the Bank
     * @param  {address} _bankEthAddress address of the Bank
     * @param  {string} _registrationNumber  registration Number of the Bank
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function addBank(
        string memory _bankName,
        address _bankEthAddress,
        string memory _registrationNumber
    ) public returns (uint8) {
        require(msg.sender == admin, "You are not an admin");
        require(
            banks[_bankEthAddress].ethAddress == address(0),
            "Bank  address is already exists"
        );
        banks[_bankEthAddress].ethAddress = _bankEthAddress;
        banks[_bankEthAddress].bankName = _bankName;
        banks[_bankEthAddress].regNumber = _registrationNumber;
        banks[_bankEthAddress].kycCount = 0;
        banks[_bankEthAddress].upvotes = 0;
        banks[_bankEthAddress].rating = 0;

        bankSize++;
        return 1;

    }

    /**
     * Remove Bank
     * @param  {address} _bankEthAddress address of the Bank
     * @return {uint8}         A 0 indicates failure, 1 indicates success
     */
    function removeBank(address _bankEthAddress) public returns (uint8) {
        require(msg.sender == admin, "You are not an admin");
        require(
            banks[_bankEthAddress].ethAddress != address(0),
            "Bank  address does not exists in the record"
        );
        delete banks[_bankEthAddress];

        bankSize--;
        return 1;

    }

    // if you are using string, you can use the following function to compare two strings
    // function to compare two string value
    // This is an internal fucntion to compare string values
    // @Params - String a and String b are passed as Parameters
    // @return - This function returns true if strings are matched and false if the strings are not matching
    function stringsEquals(string storage _a, string memory _b)
        internal
        view
        returns (bool)
    {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length) return false;
        // @todo unroll this loop
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] != b[i]) return false;
        }
        return true;
    }

}
