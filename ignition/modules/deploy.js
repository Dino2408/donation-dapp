import hre from "hardhat";
async function main() {
  console.log("Đang chuẩn bị deploy...");

  // 1. Lấy code contract
  // Chú ý: "DonationDApp_V3" phải đúng tên contract trong file .sol (class name)
  const Donation = await hre.ethers.getContractFactory("DonationDApp");

  // 2. Gửi lệnh deploy lên mạng
  const donation = await Donation.deploy();

  // 3. Đợi mạng xác nhận
  await donation.waitForDeployment();

  console.log("✅ Đã deploy thành công!");
  console.log("Địa chỉ Contract:", await donation.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});