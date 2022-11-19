const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ICOFactory", function () {
    let owner, admin, addr1, addr2, addr3, addr4; //Owner = deployer of factory contract, addr1 = project owner
    let tokenInstance;
    let factoryInstance, icoInstance;
  
    describe("Setup", () => {
        it("Should deploy Mock Token and transfer total supply to addr1", async function () {
            [owner, admin, addr1, addr2, addr3, addr4] =
                await ethers.getSigners();
            const Token = await ethers.getContractFactory("MockToken");
            tokenInstance = await Token.connect(addr1).deploy();
            await tokenInstance.deployed();
            expect(await tokenInstance.balanceOf(addr1.address)).to.equal(
                await tokenInstance.totalSupply()
            );
        });
      
        it("Should deploy factory and start a new constant ICO", async function () {
            const Factory = await ethers.getContractFactory("ICOfactory");
            factoryInstance = await Factory.deploy();
            await factoryInstance.deployed();
            await factoryInstance.createICO(
                admin.address,
                addr1.address,
                tokenInstance.address,
                "3",
                "100000000000000000000",
                Math.floor(Date.now() / 1000) + 3,
                Math.floor(Date.now() / 1000) + 30,
                false
            );
            //Total tokens = 10 million, Denominations of token per atto = 3, Hard cap = 3 million ONE (changed for some tests)
            [icoAddress] = await factoryInstance.getICOs();
            icoInstance = await hre.ethers.getContractAt("ICO", icoAddress);
            expect(await icoInstance.projectOwner()).to.equal(addr1.address);
        });
      
        it("Project owner should transfer tokens to ICO contract", async function () {
            const balance = await tokenInstance.balanceOf(addr1.address);

            await tokenInstance.connect(addr1).transfer(icoAddress, balance); //Project owner transfers tokens to the ICO contract
            expect(await tokenInstance.balanceOf(icoAddress)).to.equal(
                await tokenInstance.totalSupply()
            );
        });
    });
  
    const delay = (ms) => {
        const startPoint = new Date().getTime();
        while (new Date().getTime() - startPoint <= ms) {}
    };
  
    describe("Constant ICO tests", () => {
        it("Should be able to buy tokens once sale is active", async function () {
            delay(10000);
            const tx = await icoInstance
                .connect(addr2)
                .buyTokens({ value: ethers.utils.parseEther("1") });

            await tx.wait();
            expect(await tokenInstance.balanceOf(addr2.address)).to.equal(
                ethers.utils.parseEther("3")
            );
        });
      
        it("Should refund surplus and start timeout on 50+ spent", async function () {
            //TIMEOUT TESTED WITH 50 ONE (ETH) and 5s timeout
            const prev_balance = await ethers.provider.getBalance(
                addr2.address
            );

            const tx = await icoInstance
                .connect(addr2)
                .buyTokens({ value: ethers.utils.parseEther("70") });
            await tx.wait();
            const new_balance = await ethers.provider.getBalance(addr2.address);

            expect(await tokenInstance.balanceOf(addr2.address)).to.equal(
                ethers.utils.parseEther("150")
            );
            const limit = await icoInstance.limits(addr2.address);
            expect(limit.amount).to.equal(0);
            //console.log(limit.timeout);
            // console.log(ethers.utils.formatEther(prev_balance));
            // console.log(ethers.utils.formatEther(new_balance));
        });
      
        it("Should be able to reinvest after timeout has expired", async function () {
            delay(6000);
            const tx = await icoInstance
                .connect(addr2)
                .buyTokens({ value: ethers.utils.parseEther("10") });
            await tx.wait();
            expect(await tokenInstance.balanceOf(addr2.address)).to.equal(
                ethers.utils.parseEther("180")
            );
            const limit = await icoInstance.limits(addr2.address);
            expect(limit.amount).to.equal(ethers.utils.parseEther("10"));
        });

        it("Should refund surplus amount on reaching hardcap", async function () {
            //Tested with hardcap set to 100
            const tx1 = await icoInstance
                .connect(addr3)
                .buyTokens({ value: ethers.utils.parseEther("20") });
            await tx1.wait();
            expect(await tokenInstance.balanceOf(addr3.address)).to.equal(
                ethers.utils.parseEther("60")
            );
            //Total at 80. Accept 20 and refund rest on the next transfer
            const prev_balance = await ethers.provider.getBalance(
                addr4.address
            );
            const tx2 = await icoInstance
                .connect(addr4)
                .buyTokens({ value: ethers.utils.parseEther("50") });
            await tx2.wait();
            const new_balance = await ethers.provider.getBalance(addr4.address);
            expect(await tokenInstance.balanceOf(addr4.address)).to.equal(
                ethers.utils.parseEther("60")
            );
            // console.log(ethers.utils.formatEther(prev_balance));
            // console.log(ethers.utils.formatEther(new_balance));
        });
      
        it("Should mark ICO end on hardcap reached", async function () {
            expect(await icoInstance.isActive(), false);
        });
      
        it("Admin should be able to withdraw raised amount on ICO end", async function () {
            delay(18000);
            const project_owner = await icoInstance.projectOwner();
            const prev_owner_balance = await ethers.provider.getBalance(
                project_owner
            );
            const prev_admin_balance = await ethers.provider.getBalance(
                admin.address
            );
            await icoInstance.connect(admin).withdraw();
            const new_owner_balance = await ethers.provider.getBalance(
                project_owner
            );
            const new_admin_balance = await ethers.provider.getBalance(
                admin.address
            );
            // const raised_amount = await icoInstance.raisedAmount();
            // console.log(raised_amount);
            // console.log(prev_owner_balance);
            // console.log(new_owner_balance);
            expect(prev_admin_balance).to.be.below(new_admin_balance);
            expect(prev_owner_balance).to.be.below(new_owner_balance);
        });
      
        it("Should transfer unsold tokens to project owner on ICO end", async function () {
            const prev_balance = await tokenInstance.balanceOf(addr1.address);
            await icoInstance.connect(admin).withdrawTokens();
            const new_balance = await tokenInstance.balanceOf(addr1.address);
            expect(new_balance).to.be.above(prev_balance);
            expect(await tokenInstance.balanceOf(icoAddress)).to.equal(0);
        });
      
    });
    describe("Weighted ICO tests", () => {
        let weightedIcoAddr, weightedInstance;
        let tokenInstance2;
        it("Should start a weighted ICO", async function () {
            const Token2 = await ethers.getContractFactory("MockToken");
            tokenInstance2 = await Token2.connect(addr2).deploy();
            await tokenInstance2.deployed();
            expect(await tokenInstance2.balanceOf(addr2.address)).to.equal(
                await tokenInstance2.totalSupply()
            );
            await factoryInstance.createICO(
                admin.address,
                addr2.address,
                tokenInstance2.address,
                "3",
                "100000000000000000000",
                Math.floor(Date.now() / 1000) + 10,
                Math.floor(Date.now() / 1000) + 360,
                true
            );

            [, weightedIcoAddr] = await factoryInstance.getICOs();
            weightedInstance = await hre.ethers.getContractAt(
                "ICO",
                weightedIcoAddr
            );
            expect(await weightedInstance.weighted()).to.equal(true);
        });
      
        it("Should transfer tokens to ICO contract", async function () {
            const balance = await tokenInstance2.balanceOf(addr2.address);
            await tokenInstance2
                .connect(addr2)
                .transfer(weightedIcoAddr, balance);
            expect(await tokenInstance2.balanceOf(weightedIcoAddr)).to.equal(
                balance
            );
        });

        it("Should give back proper ratio of tokens", async function () {
            delay(15000);
            //Before 1/3rd
            const tx1 = await weightedInstance
                .connect(addr1)
                .buyTokens({ value: ethers.utils.parseEther("30") });

            await tx1.wait();
            expect(await tokenInstance2.balanceOf(addr1.address)).to.equal(
                ethers.utils.parseEther("90")
            );
            const tx2 = await weightedInstance
                .connect(addr1)
                .buyTokens({ value: ethers.utils.parseEther("10") });

            await tx2.wait();
            expect(await tokenInstance2.balanceOf(addr1.address)).to.equal(
                ethers.utils.parseEther("105")
            );

            const tx3 = await weightedInstance
                .connect(addr3)
                .buyTokens({ value: ethers.utils.parseEther("40") });

            await tx3.wait();
            expect(await tokenInstance2.balanceOf(addr3.address)).to.equal(
                ethers.utils.parseEther("40")
            );
        });
      
        it("Admin should be able to update token price", async function () {
            const tx = await weightedInstance.connect(admin).updateTokenPrice();
            await tx.wait();
            expect(await weightedInstance.tokensPerAtto()).to.equal(1);
        });
    });
});
