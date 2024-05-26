## Intent Availability Layer 

## Project Structure 
- **./broker/..**: Off-chain auction logic for solver selection
- **./src/..**: All smart contracts associated with the procject 
- **./src/handlers/..**: Includes 2 handler implementations, one for signed transfers and one for uni v3 swaps. Handlers can be implemented for any range of generic intent verification.
- **./src/AccountEntryPoint**: This is the account factory as well as the main entry point for executing intents on accounts. Intents are executed by the trusted party running the off chain auction for selecting best execution.
- **./src/AccountStorage**: Transient storage contract used to access shared storage in handlers and accounts.