// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ScuffDirectives.sol";
import "./BasicOrderParametersPointerLibrary.sol";
import "seaport-sol/../PointerLibraries.sol";

type FulfillBasicOrderPointer is uint256;

using Scuff for MemoryPointer;
using FulfillBasicOrderPointerLibrary for FulfillBasicOrderPointer global;

/// @dev Library for resolving pointers of encoded calldata for
/// fulfillBasicOrder(BasicOrderParameters)
library FulfillBasicOrderPointerLibrary {
  enum ScuffKind { parameters_HeadOverflow, parameters_considerationToken_Overflow, parameters_offerer_Overflow, parameters_zone_Overflow, parameters_offerToken_Overflow, parameters_basicOrderType_Overflow, parameters_additionalRecipients_HeadOverflow, parameters_additionalRecipients_LengthOverflow, parameters_additionalRecipients_element_recipient_Overflow, parameters_signature_HeadOverflow, parameters_signature_LengthOverflow, parameters_signature_DirtyLowerBits }

  uint256 internal constant HeadSize = 0x20;
  uint256 internal constant MinimumParametersScuffKind = uint256(ScuffKind.parameters_considerationToken_Overflow);
  uint256 internal constant MaximumParametersScuffKind = uint256(ScuffKind.parameters_signature_DirtyLowerBits);

  /// @dev Convert a `MemoryPointer` to a `FulfillBasicOrderPointer`.
  /// This adds `FulfillBasicOrderPointerLibrary` functions as members of the pointer
  function wrap(MemoryPointer ptr) internal pure returns (FulfillBasicOrderPointer) {
    return FulfillBasicOrderPointer.wrap(MemoryPointer.unwrap(ptr.offset(4)));
  }

  /// @dev Convert a `FulfillBasicOrderPointer` back into a `MemoryPointer`.
  function unwrap(FulfillBasicOrderPointer ptr) internal pure returns (MemoryPointer) {
    return MemoryPointer.wrap(FulfillBasicOrderPointer.unwrap(ptr));
  }

  /// @dev Convert a `bytes` with encoded calldata for `fulfillBasicOrder`to a `FulfillBasicOrderPointer`.
  /// This adds `FulfillBasicOrderPointerLibrary` functions as members of the pointer
  function fromBytes(bytes memory data) internal pure returns (FulfillBasicOrderPointer ptrOut) {
    assembly {
      ptrOut := add(data, 0x24)
    }
  }

  /// @dev Resolve the pointer to the head of `parameters` in memory.
  /// This points to the offset of the item's data relative to `ptr`
  function parametersHead(FulfillBasicOrderPointer ptr) internal pure returns (MemoryPointer) {
    return ptr.unwrap();
  }

  /// @dev Resolve the `BasicOrderParametersPointer` pointing to the data buffer of `parameters`
  function parametersData(FulfillBasicOrderPointer ptr) internal pure returns (BasicOrderParametersPointer) {
    return BasicOrderParametersPointerLibrary.wrap(ptr.unwrap().offset(parametersHead(ptr).readUint256()));
  }

  /// @dev Add dirty bits to the head for `parameters` (offset relative to parent).
  function addDirtyBitsToParametersOffset(FulfillBasicOrderPointer ptr) internal pure {
    parametersHead(ptr).addDirtyBitsBefore(224);
  }

  /// @dev Resolve the pointer to the tail segment of the encoded calldata.
  /// This is the beginning of the dynamically encoded data.
  function tail(FulfillBasicOrderPointer ptr) internal pure returns (MemoryPointer) {
    return ptr.unwrap().offset(HeadSize);
  }

  function addScuffDirectives(FulfillBasicOrderPointer ptr, ScuffDirectivesArray directives, uint256 kindOffset) internal pure {
    /// @dev Overflow offset for `parameters`
    directives.push(Scuff.lower(uint256(ScuffKind.parameters_HeadOverflow) + kindOffset, 224, ptr.parametersHead()));
    /// @dev Add all nested directives in parameters
    ptr.parametersData().addScuffDirectives(directives, kindOffset + MinimumParametersScuffKind);
  }

  function getScuffDirectives(FulfillBasicOrderPointer ptr) internal pure returns (ScuffDirective[] memory) {
    ScuffDirectivesArray directives = Scuff.makeUnallocatedArray();
    addScuffDirectives(ptr, directives, 0);
    return directives.finalize();
  }

  function toString(ScuffKind k) internal pure returns (string memory) {
    if (k == ScuffKind.parameters_HeadOverflow) return "parameters_HeadOverflow";
    if (k == ScuffKind.parameters_considerationToken_Overflow) return "parameters_considerationToken_Overflow";
    if (k == ScuffKind.parameters_offerer_Overflow) return "parameters_offerer_Overflow";
    if (k == ScuffKind.parameters_zone_Overflow) return "parameters_zone_Overflow";
    if (k == ScuffKind.parameters_offerToken_Overflow) return "parameters_offerToken_Overflow";
    if (k == ScuffKind.parameters_basicOrderType_Overflow) return "parameters_basicOrderType_Overflow";
    if (k == ScuffKind.parameters_additionalRecipients_HeadOverflow) return "parameters_additionalRecipients_HeadOverflow";
    if (k == ScuffKind.parameters_additionalRecipients_LengthOverflow) return "parameters_additionalRecipients_LengthOverflow";
    if (k == ScuffKind.parameters_additionalRecipients_element_recipient_Overflow) return "parameters_additionalRecipients_element_recipient_Overflow";
    if (k == ScuffKind.parameters_signature_HeadOverflow) return "parameters_signature_HeadOverflow";
    if (k == ScuffKind.parameters_signature_LengthOverflow) return "parameters_signature_LengthOverflow";
    return "parameters_signature_DirtyLowerBits";
  }

  function toKind(uint256 k) internal pure returns (ScuffKind) {
    return ScuffKind(k);
  }
}