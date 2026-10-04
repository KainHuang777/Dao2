// Build companions only; existing export bytes remain immutable.
// No Node dependency in game rules or runtime. Built-in zlib/filesystem only.
import { readFileSync, writeFileSync, realpathSync, mkdirSync, copyFileSync } from 'node:fs';
import { resolve, relative, sep, isAbsolute } from 'node:path';
import { createHash } from 'node:crypto';
import { brotliCompressSync, brotliDecompressSync, constants } from 'node:zlib';
const root = realpathSync(new URL('..', import.meta.url));
const directory = realpathSync(resolve(process.argv[2] ?? resolve(root, 'build/web')));
const insideBuild = relative(resolve(root, 'build'), directory);
if (isAbsolute(insideBuild) || insideBuild.startsWith('..') || insideBuild.includes('..' + sep)) throw new Error('Expected project build directory');
const sha = data => createHash('sha256').update(data).digest('hex');
// Optional soundtrack assets are copied byte-for-byte; no transcoding or cuts.
const audioDirectory = resolve(directory, 'audio/bgm');
mkdirSync(audioDirectory, {recursive:true});
const audioFiles = [];
for (const entry of JSON.parse(readFileSync(resolve(root,'assets/audio/bgm/library.json'),'utf8'))) {
  if (!/^0[1-4]_[A-Za-z_]+\.mp3$/.test(entry.filename)) throw new Error('Unexpected BGM filename');
  const source = resolve(root,'src/BGM',entry.filename);
  copyFileSync(source, resolve(audioDirectory,entry.filename));
  const data = readFileSync(source);
  audioFiles.push({file:'audio/bgm/'+entry.filename, era_req:entry.era_req, bytes:data.length, sha256:sha(data)});
}
const files = [];
for (const file of ['index.js', 'index.wasm', 'index.pck']) {
  const original = readFileSync(resolve(directory, file));
  const compressed = brotliCompressSync(original, {params:{
    [constants.BROTLI_PARAM_QUALITY]: 9,
    [constants.BROTLI_PARAM_SIZE_HINT]: original.length,
  }});
  if (!brotliDecompressSync(compressed).equals(original)) throw new Error('Compression roundtrip mismatch');
  writeFileSync(resolve(directory, file + '.br'), compressed);
  files.push({file, bytes:original.length, sha256:sha(original), br_bytes:compressed.length, br_sha256:sha(compressed)});
}
const report = {generator:'tools/prepare_web_compression.mjs', node:process.version, quality:9, files, audioFiles,
  br_bytes:files.reduce((sum,file)=>sum+file.br_bytes,0)};
writeFileSync(resolve(directory, 'compression.json'), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify(report));
