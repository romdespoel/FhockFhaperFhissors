import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const owner_fee_percent = 10;
const ONE_GWEI: bigint = 1_000_000_000n;

const FhockFhaperFhissorsModule = buildModule("FhockFhaperFhissorsModule", (m) => {
  const contract = m.contract("FhockFhaperFhissors", [owner_fee_percent], {
    value: ONE_GWEI,
  });

  return { contract };
});

export default FhockFhaperFhissorsModule;
