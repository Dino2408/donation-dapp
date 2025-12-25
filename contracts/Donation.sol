// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract DonationDApp {
    address public owner;

    // Cấu trúc một Dự án
    struct Campaign {
        uint256 id;
        address creator;
        string title;
        string description;
        string image;
        uint256 target;
        uint256 raised;         // Tổng số tiền đã huy động (Chỉ tăng)
        uint256 currentBalance; // Số dư hiện tại của dự án (Tăng khi donate, Giảm khi rút)
        bool isOpen;
    }

    // Cấu trúc lịch sử quyên góp
    struct Donation {
        uint256 campaignId;
        address donor;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    // Cấu trúc lịch sử rút tiền
    struct Withdrawal {
        uint256 id;
        address to;
        uint256 amount;
        string reason;
        string proof;
        uint256 timestamp;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => Withdrawal[]) public campaignWithdrawals; 
    uint256 public campaignCount = 0;
    Donation[] public donations;

    // Sự kiện
    event CampaignCreated(uint256 id, string title, uint256 target);
    event NewDonation(uint256 indexed campaignId, address indexed donor, uint256 amount, string message);
    event FundsWithdrawn(uint256 indexed campaignId, address indexed to, uint256 amount, string reason, uint256 timestamp);
    event ProofAdded(uint256 indexed campaignId, uint256 withdrawalIndex, string proof);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Chi Admin moi duoc thao tac");
        _;
    }

    // 1. TẠO DỰ ÁN MỚI
    function createCampaign(string memory _title, string memory _desc, string memory _image, uint256 _target) public onlyOwner {
        campaigns[campaignCount] = Campaign({
            id: campaignCount,
            creator: msg.sender,
            title: _title,
            description: _desc,
            image: _image,
            target: _target,
            raised: 0,
            currentBalance: 0, // Khởi tạo số dư bằng 0
            isOpen: true
        });

        emit CampaignCreated(campaignCount, _title, _target);
        campaignCount++;
    }

    // 2. QUYÊN GÓP (Tăng raised VÀ currentBalance)
    function donateToCampaign(uint256 _id, string memory _message) public payable {
        require(msg.value > 0, "So tien phai > 0");
        require(_id < campaignCount, "Du an khong ton tai");
        require(campaigns[_id].isOpen, "Du an da dong");

        // Cộng tiền vào tổng huy động (chỉ tăng để hiển thị thành tích)
        campaigns[_id].raised += msg.value;
        
        // Cộng tiền vào số dư thực tế (để admin rút sau này)
        campaigns[_id].currentBalance += msg.value;

        donations.push(Donation(_id, msg.sender, msg.value, _message, block.timestamp));
        emit NewDonation(_id, msg.sender, msg.value, _message);
    }

    // 3. RÚT TIỀN (Rút từ currentBalance của dự án đó)
    function withdrawFromCampaign(uint256 _id, address payable _to, string memory _reason) public onlyOwner {
        // Kiểm tra số dư CỦA RIÊNG DỰ ÁN ĐÓ
        require(campaigns[_id].currentBalance > 0, "Du an nay da het tien");

        uint256 amountToWithdraw = campaigns[_id].currentBalance;
        
        // Reset số dư của dự án về 0 TRƯỚC khi chuyển tiền (Chống lỗi Reentrancy)
        campaigns[_id].currentBalance = 0;

        // Thực hiện chuyển tiền
        (bool success, ) = _to.call{value: amountToWithdraw}("");
        require(success, "Giao dich rut tien that bai");

        // Lưu lịch sử rút
        uint256 withdrawalId = campaignWithdrawals[_id].length;
        campaignWithdrawals[_id].push(Withdrawal(withdrawalId, _to, amountToWithdraw, _reason, "", block.timestamp));

        emit FundsWithdrawn(_id, _to, amountToWithdraw, _reason, block.timestamp);
    }

    // 4. CẬP NHẬT MINH CHỨNG
    function addProofToWithdrawal(uint256 _campaignId, uint256 _withdrawalIndex, string memory _proof) public onlyOwner {
        require(_withdrawalIndex < campaignWithdrawals[_campaignId].length, "Giao dich khong ton tai");
        campaignWithdrawals[_campaignId][_withdrawalIndex].proof = _proof;
        emit ProofAdded(_campaignId, _withdrawalIndex, _proof);
    }

    // Các hàm View
    function toggleCampaignStatus(uint256 _id) public onlyOwner {
        campaigns[_id].isOpen = !campaigns[_id].isOpen;
    }

    function getCampaignWithdrawals(uint256 _campaignId) public view returns (Withdrawal[] memory) {
        return campaignWithdrawals[_campaignId];
    }

    function getAllDonations() public view returns (Donation[] memory) {
        return donations;
    }
}