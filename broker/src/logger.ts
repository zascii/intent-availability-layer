import { createLogger, format, transports } from "winston";

const { combine, timestamp, printf, colorize } = format;

const myFormat = printf(({ level, message, timestamp }) => {
  return `${timestamp} ${level}: ${message}`;
});

const logger = createLogger({
  level: "info", // Log only if info level or higher
  format: combine(colorize(), timestamp(), myFormat),
  transports: [
    new transports.Console(), // Log to console
  ],
});

export default logger;
