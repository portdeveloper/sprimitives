// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

// import "forge-std/Test.sol";

type Whatever is uint256;

type ptr is bytes32;

using Pointers for ptr;
// using {$$ as +} for ptr global;

function eq(ptr p1, ptr p2) pure returns (bool) {
    return ptr.unwrap(p1) == ptr.unwrap(p2);
}

function neq(ptr p1, ptr p2) pure returns (bool) {
    return ptr.unwrap(p1) != ptr.unwrap(p2);
}

function add(ptr p1, ptr p2) pure returns (ptr) {
    return Pointers.$(p1, p2);
}

using {eq as ==, neq as !=, add as +} for ptr global;

library Pointers {
    function $(bytes32 offset) internal pure returns (ptr ret) {
        ret = ptr.wrap(offset);
        // assembly {
        //     mstore(0x00, offset)
        //     ret := keccak256(0x00, 0x20)
        // }
    }

    function $(ptr offset) internal pure returns (ptr ret) {
        ret = $(ptr.unwrap(offset));
    }

    function $(bytes32 base, bytes32 offset) internal pure returns (ptr ret) {
        assembly {
            mstore(0x00, base)
            mstore(0x20, offset)
            ret := keccak256(0x00, 0x40)
        }
        ret = ptr.wrap(keccak256(abi.encodePacked(base, ptr.unwrap($(offset)))));
    }

    function $(ptr base, bytes32 offset) internal pure returns (ptr ret) {
        ret = $(ptr.unwrap(base), offset);
    }

    function $(bytes32 base, ptr offset) internal pure returns (ptr ret) {
        ret = $(base, ptr.unwrap(offset));
    }

    function $(ptr base, ptr offset) internal pure returns (ptr ret) {
        ret = $(ptr.unwrap(base), ptr.unwrap(offset));
    }

    function store(ptr loc, uint256 value) internal returns (ptr) {
        assembly {
            sstore(loc, value)
        }
        return loc;
    }

    function store(ptr loc, ptr value) internal returns (ptr) {
        assembly {
            sstore(loc, value)
        }
        return loc;
    }

    function store(ptr loc, address value) internal returns (ptr) {
        assembly {
            sstore(loc, value)
        }
        return loc;
    }

    function store(ptr loc, string memory value) internal returns (ptr) {
        bytes memory data = bytes(value);
        assembly {
            sstore(loc, add(data, 0x20)) // store the pointer to the data
            sstore(add(loc, 1), mload(data)) // store the length of the data
        }
        for (uint256 i = 0; i < data.length; i += 32) {
            bytes32 chunk;
            assembly {
                chunk := mload(add(data, add(0x20, i)))
            }
            assembly {
                sstore(add(loc, add(2, div(i, 32))), chunk)
            }
        }
        return loc;
    }

    function load(ptr loc) internal view returns (uint256 value) {
        assembly {
            value := sload(loc)
        }
    }

    function loadAddress(ptr loc) internal view returns (address value) {
        assembly {
            value := sload(loc)
        }
    }

    function loadString(ptr loc) internal view returns (string memory value) {
        uint256 length;
        bytes32 dataPointer;
        assembly {
            dataPointer := sload(loc)
            length := sload(add(loc, 1))
        }
        bytes memory data = new bytes(length);
        for (uint256 i = 0; i < length; i += 32) {
            bytes32 chunk;
            assembly {
                chunk := sload(add(loc, add(2, div(i, 32))))
            }
            for (uint256 j = 0; j < 32 && i + j < length; j++) {
                data[i + j] = chunk[j];
            }
        }
        value = string(data);
    }

    // function load(ptr key) internal view returns (uint256 value) {
    //     ptr loc = key.ptr();
    //     value = load_ptr(loc);
    // }
}

function $(bytes32 offset) pure returns (ptr) {
    return Pointers.$(offset);
}

function $(ptr offset) pure returns (ptr) {
    return Pointers.$(offset);
}

function $$(ptr offset) pure returns (ptr) {
    return Pointers.$(offset);
}

function str2ptr(bytes memory str) pure returns (ptr p) {
    uint256 i = 0;
    uint256 j = 0;
    uint256 neg1 = type(uint256).max;
    ptr token;
    uint256 len = bytes(str).length;

    while (true) {
        require(i - j < 0x20, "str2ptr: string too long");

        if (i == len || str[i] == ".") {
            assembly {
                token := and(mload(add(add(str, 0x20), j)), not(shr(shl(3, sub(i, j)), neg1)))
            }

            if (j == 0) {
                // it is the first base token
                p = $(token);
            } else {
                // it is offset token
                p = p.$(token);
            }

            if (i == len) {
                break;
            }

            j = i + 1;
        }

        i++;
    }
}

