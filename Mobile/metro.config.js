// https://docs.expo.dev/guides/customizing-metro
const { getDefaultConfig } = require("expo/metro-config");

/** @type {import('expo/metro-config').MetroConfig} */
const config = getDefaultConfig(__dirname);

// Support .wasm files required by expo-sqlite on web.
// Remove "wasm" from sourceExts (if present) and add to assetExts so Metro
// treats it as a binary asset rather than trying to parse it as JS.
config.resolver.sourceExts = config.resolver.sourceExts.filter(
  (ext) => ext !== "wasm"
);
config.resolver.assetExts.push("wasm");

module.exports = config;
