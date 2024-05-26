import { z, ZodError } from "zod";

// Validator for Ethereum addresses
export const EthereumAddressSchema = z.string().refine(
  (data) => {
    // Check if the address starts with '0x' and is exactly 42 characters long
    return (
      data.startsWith("0x") &&
      data.length === 42 &&
      /^[0-9a-fA-F]+$/.test(data.substring(2))
    );
  },
  {
    message: "Invalid Ethereum address", // Custom error message
  }
);

const NumericStringSchema = z.string().regex(/^\d+$/, {
  message: "Invalid format. The string must contain only numbers.",
});

/**
 * Should match the swap function in UniswapV3SwapHandler.sol sans the path
 * which is provided by the solver
 */
export const IntentEndpointSchema = z.object({
  tokenIn: EthereumAddressSchema,
  tokenOut: EthereumAddressSchema,
  amountIn: NumericStringSchema,
  minOut: NumericStringSchema, // Demoninated in output token terms
});

export const SolveEndpointSchema = z.object({
  intentKey: z.string(),
  path: z.array(EthereumAddressSchema),
  amountIn: NumericStringSchema,
  minOut: NumericStringSchema,
});
