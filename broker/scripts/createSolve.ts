import { ethers } from "ethers";
import {
  AAVEGOTCHI_TOKEN_ADDRESS,
  BASE_TOKEN_ADDRESS,
  USDC_TOKEN_ADDRESS,
} from "../src/consts";

const shortRouteUsdcToBase = () => {
  return ethers.solidityPacked(
    ["address", "uint24", "address"],
    [BASE_TOKEN_ADDRESS, 3000, USDC_TOKEN_ADDRESS]
  );
};

const longRouteUsdcToBase = () => {
  return ethers.solidityPacked(
    ["address", "uint24", "address", "uint24", "address"],
    [
      USDC_TOKEN_ADDRESS,
      3000,
      AAVEGOTCHI_TOKEN_ADDRESS,
      3000,
      BASE_TOKEN_ADDRESS,
    ]
  );
};

const shortRoute = shortRouteUsdcToBase();
const longRoute = longRouteUsdcToBase();
console.log({
  shortRoute,
  longRoute,
});
