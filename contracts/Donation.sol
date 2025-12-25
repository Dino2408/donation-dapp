// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonationDApp {
    address public owner;

    // Cấu trúc một Dự án
    struct Campaign {
        uint256 id;
        address creator;
        string title;
        string description;
        string image;       // Link ảnh bìa dự án
        uint256 target;     // Mục tiêu (Wei)
        uint256 raised;     // Đã đạt được (Wei)
        bool isOpen;        // Trạng thái (Đóng/Mở)
    }

    // Cấu trúc lịch sử quyên góp
    struct Donation {
        uint256 campaignId;
        address donor;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    // Lưu danh sách các dự án
    mapping(uint256 => Campaign) public campaigns;
    uint256 public campaignCount = 0;

    // Lưu danh sách lịch sử quyên góp
    Donation[] public donations;

    // Sự kiện
    event CampaignCreated(uint256 id, string title, uint256 target);
    event NewDonation(uint256 indexed campaignId, address indexed donor, uint256 amount, string message);
    event CampaignClosed(uint256 id);
    event FundsWithdrawn(uint256 indexed campaignId, address indexed to, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Chi Admin moi duoc thao tac");
        _;
    }

    // 1. TẠO DỰ ÁN MỚI (Chỉ Admin)
    function createCampaign(string memory _title, string memory _desc, string memory _image, uint256 _target) public onlyOwner {
        campaigns[campaignCount] = Campaign({
            id: campaignCount,
            creator: msg.sender,
            title: _title,
            description: _desc,
            image: _image,
            target: _target,
            raised: 0,
            isOpen: true
        });

        emit CampaignCreated(campaignCount, _title, _target);
        campaignCount++;
    }

    // 2. QUYÊN GÓP CHO DỰ ÁN CỤ THỂ
    function donateToCampaign(uint256 _id, string memory _message) public payable {
        require(msg.value > 0, "So tien phai > 0");
        require(_id < campaignCount, "Du an khong ton tai");
        require(campaigns[_id].isOpen, "Du an da dong");

        // Cộng tiền vào dự án đó
        campaigns[_id].raised += msg.value;

        // Lưu lịch sử
        donations.push(Donation(_id, msg.sender, msg.value, _message, block.timestamp));

        emit NewDonation(_id, msg.sender, msg.value, _message);
    }

    // 3. RÚT TIỀN TỪ DỰ ÁN (Chỉ Admin)
    // Admin có thể rút tiền của dự án bất cứ lúc nào, nhưng phải chỉ định rút từ dự án nào
    function withdrawFromCampaign(uint256 _id, address payable _to) public onlyOwner {
        require(_id < campaignCount, "Du an khong ton tai");
        
        // Rút toàn bộ tiền hiện có trong contract (đơn giản hóa)
        // Lưu ý thực tế: Nên tracking balance riêng của từng campaign nếu muốn phức tạp hơn
        // Ở đây ta dùng logic: Tiền trong ví contract là tiền chung, nhưng ta rút dựa trên số raised.
        // Để an toàn và đơn giản cho demo: Ta rút số dư thực tế của Contract.
        
        uint256 balance = address(this).balance;
        require(balance > 0, "Khong co tien trong quy");

        (bool success, ) = _to.call{value: balance}("");
        require(success, "Rut tien that bai");

        emit FundsWithdrawn(_id, _to, balance);
    }

    // 4. ĐÓNG DỰ ÁN (Không nhận tiền nữa)
    function toggleCampaignStatus(uint256 _id) public onlyOwner {
        campaigns[_id].isOpen = !campaigns[_id].isOpen;
    }

    // Lấy toàn bộ danh sách quyên góp
    function getAllDonations() public view returns (Donation[] memory) {
        return donations;
    }
}