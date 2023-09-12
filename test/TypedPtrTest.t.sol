// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "../src/TypedPtr.sol";

import "forge-std/Test.sol";

using Pointers for ptr;

contract TypedPtrsTest is Test {
    //old tests for reference
    function setUp() external {
        ptr loc = $("root").store(55);
        ptr child = loc.$("child").$("leaf").store(66);
        console.log(loc.load());
        console.log(child.load());

        ptr test1 = $("storage").$("is").$("a").$("tree").store(123);
        ptr test2 = ($("storage").$("is").$("a") + $("tree")).store(456);
        ptr test3 = str2ptr("storage.is.a.tree");
        console.log("%x => %d", uint256(ptr.unwrap(test3)), test3.load());
        require(test1 == test2 && test2 == test3, "ptr mismatch");
    }

    function testPtrs() public returns (ptr) {
        console.log($("root").load());
        console.log($("root").$("child").$("leaf").load());
    }

    function testBasicPointerOperations() public {
        ptr base = $("base");
        ptr offset1 = $("offset1");
        ptr offset2 = $("offset2");

        ptr combined1 = base.$(offset1);
        ptr combined2 = base + offset2;

        require(base != offset1, "Base and offset1 should not be equal");
        require(combined1 != combined2, "Combined pointers should not be equal");
    }

    function testUintStorage() public {
        ptr loc = $("uintTestLocation");
        uint256 value = 123456;

        loc.store(value);
        uint256 retrievedValue = loc.load();

        require(retrievedValue == value, "Stored and retrieved uint256 values do not match");
    }

    function testAddressStorageRetrieval() public {
        ptr loc = $("addressTestLocation2");
        address testAddress = 0x1234567890123456789012345678901234567890;

        loc.store(testAddress);
        address retrievedAddress = loc.loadAddress();

        require(retrievedAddress == testAddress, "Stored and retrieved addresses do not match");
    }

    function testStringStorageRetrieval() public {
        ptr loc = $("stringTestLocation2");
        string memory testString = "This is another test string";

        loc.store(testString);
        string memory retrievedString = loc.loadString();

        require(
            keccak256(abi.encodePacked(retrievedString)) == keccak256(abi.encodePacked(testString)),
            "Stored and retrieved strings do not match"
        );
    }

    function testStr2PtrConversion() public {
        string memory testStr = "test1.test2.test3";
        ptr convertedPtr = str2ptr(bytes(testStr)); // Convert string to bytes

        ptr expectedPtr = $("test1").$("test2").$("test3");
        require(convertedPtr == expectedPtr, "Converted pointer does not match expected pointer");
    }
}
