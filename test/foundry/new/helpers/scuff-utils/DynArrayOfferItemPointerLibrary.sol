pragma solidity ^0.8.17;

import "./ScuffDirectives.sol";
import "./OfferItemPointerLibrary.sol";
import "../../../../../contracts/helpers/PointerLibraries.sol";

type DynArrayOfferItemPointer is uint256;

using Scuff for MemoryPointer;
using DynArrayOfferItemPointerLibrary for DynArrayOfferItemPointer global;

/// @dev Library for resolving pointers of encoded OfferItem[]
library DynArrayOfferItemPointerLibrary {
  enum ScuffKind { length_DirtyBits, length_MaxValue, element_itemType_DirtyBits, element_itemType_MaxValue, element_token_DirtyBits, element_token_MaxValue }

  enum ScuffableField { length, element }

  uint256 internal constant CalldataStride = 0xa0;
  uint256 internal constant MinimumElementScuffKind = uint256(ScuffKind.element_itemType_DirtyBits);
  uint256 internal constant MaximumElementScuffKind = uint256(ScuffKind.element_token_MaxValue);

  /// @dev Convert a `MemoryPointer` to a `DynArrayOfferItemPointer`.
  /// This adds `DynArrayOfferItemPointerLibrary` functions as members of the pointer
  function wrap(MemoryPointer ptr) internal pure returns (DynArrayOfferItemPointer) {
    return DynArrayOfferItemPointer.wrap(MemoryPointer.unwrap(ptr));
  }

  /// @dev Convert a `DynArrayOfferItemPointer` back into a `MemoryPointer`.
  function unwrap(DynArrayOfferItemPointer ptr) internal pure returns (MemoryPointer) {
    return MemoryPointer.wrap(DynArrayOfferItemPointer.unwrap(ptr));
  }

  /// @dev Resolve the pointer to the head of the array.
  /// This points to the first item's data
  function head(DynArrayOfferItemPointer ptr) internal pure returns (MemoryPointer) {
    return ptr.unwrap().offset(_OneWord);
  }

  /// @dev Resolve the pointer to the head of `arr[index]` in memory.
  /// This points to the beginning of the encoded `OfferItem[]`
  function element(DynArrayOfferItemPointer ptr, uint256 index) internal pure returns (MemoryPointer) {
    return head(ptr).offset(index * CalldataStride);
  }

  /// @dev Resolve the pointer for the length of the `OfferItem[]` at `ptr`.
  function length(DynArrayOfferItemPointer ptr) internal pure returns (MemoryPointer) {
    return ptr.unwrap();
  }

  /// @dev Set the length for the `OfferItem[]` at `ptr` to `length`.
  function setLength(DynArrayOfferItemPointer ptr, uint256 _length) internal pure {
    length(ptr).write(_length);
  }

  /// @dev Set the length for the `OfferItem[]` at `ptr` to `type(uint256).max`.
  function setMaxLength(DynArrayOfferItemPointer ptr) internal pure {
    setLength(ptr, type(uint256).max);
  }

  /// @dev Resolve the `OfferItemPointer` pointing to the data buffer of `arr[index]`
  function elementData(DynArrayOfferItemPointer ptr, uint256 index) internal pure returns (OfferItemPointer) {
    return OfferItemPointerLibrary.wrap(head(ptr).offset(index * CalldataStride));
  }

  function addScuffDirectives(DynArrayOfferItemPointer ptr, ScuffDirectivesArray directives, uint256 kindOffset, ScuffPositions positions) internal pure {
    /// @dev Add dirty upper bits to length
    directives.push(Scuff.upper(uint256(ScuffKind.length_DirtyBits) + kindOffset, 224, ptr.length(), positions));
    /// @dev Set every bit in length to 1
    directives.push(Scuff.lower(uint256(ScuffKind.length_MaxValue) + kindOffset, 224, ptr.length(), positions));
    uint256 len = ptr.length().readUint256();
    for (uint256 i; i < len; i++) {
      ScuffPositions pos = positions.push(i);
      /// @dev Add all nested directives in element
      ptr.elementData(i).addScuffDirectives(directives, kindOffset + MinimumElementScuffKind, pos);
    }
  }

  function getScuffDirectives(DynArrayOfferItemPointer ptr) internal pure returns (ScuffDirective[] memory) {
    ScuffDirectivesArray directives = Scuff.makeUnallocatedArray();
    ScuffPositions positions = EmptyPositions;
    addScuffDirectives(ptr, directives, 0, positions);
    return directives.finalize();
  }

  function toString(ScuffKind k) internal pure returns (string memory) {
    if (k == ScuffKind.length_DirtyBits) return "length_DirtyBits";
    if (k == ScuffKind.length_MaxValue) return "length_MaxValue";
    if (k == ScuffKind.element_itemType_DirtyBits) return "element_itemType_DirtyBits";
    if (k == ScuffKind.element_itemType_MaxValue) return "element_itemType_MaxValue";
    if (k == ScuffKind.element_token_DirtyBits) return "element_token_DirtyBits";
    return "element_token_MaxValue";
  }

  function toKind(uint256 k) internal pure returns (ScuffKind) {
    return ScuffKind(k);
  }

  function toKindString(uint256 k) internal pure returns (string memory) {
    return toString(toKind(k));
  }
}