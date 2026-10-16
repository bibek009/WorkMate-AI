import path from "path";
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",

  serverExternalPackages: [
    "@ffmpeg-installer/ffmpeg",
    "fluent-ffmpeg",
    "sharp",
    "tesseract.js",
    "pdf-parse",
  ],

  turbopack: {
    root: path.resolve(__dirname),
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;