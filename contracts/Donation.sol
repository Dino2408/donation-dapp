// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonationDApp {
    
    // Cấu trúc lưu thông tin người quyên góp
    struct Donation {
        address donor;      // Địa chỉ ví người gửi
        uint256 amount;     // Số tiền (Wei)
        uint256 timestamp;  // Thời gian
        string message; // Lời nhắn
    }

    // Danh sách lưu trữ lịch sử
    Donation[] public donations;
    
    // Chủ sở hữu contract
    address public owner;

    // Biến theo dõi tổng số tiền đã nhận
    uint256 public totalDonatedAmount;
    
    // Sự kiện để báo hiệu có người vừa donate
    event NewDonation(address indexed donor, uint256 amount, string message, uint256 timestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender; // Thiết lập người tạo là chủ sở hữu
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Chi chu so huu moi duoc thuc hien");
        _;
    }

    // Hàm nhận tiền quyên góp
    function donate(string calldata _message) public payable {
        require(msg.value > 0, "So tien quyen gop phai lon hon 0");
        donations.push(Donation(msg.sender, msg.value, block.timestamp, _message));
        
        // Cộng dồn vào tổng tiền
        totalDonatedAmount += msg.value;

        emit NewDonation(msg.sender, msg.value, _message, block.timestamp);
    }

    // Hàm xem lịch sử
    function getDonations() public view returns (Donation[] memory) {
        return donations;
    }

    // 5. Hàm rút tiền 
    // Rút tiền về bất kỳ địa chỉ nào (linh hoạt hơn)
    function withdrawTo(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Khong co tien de rut");
        
        (bool success, ) = _to.call{value: balance}("");
        require(success, "Rut tien that bai");
    }

    // Hàm đổi chủ sở hữu (phòng khi mất ví)
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Dia chi khong hop le");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}