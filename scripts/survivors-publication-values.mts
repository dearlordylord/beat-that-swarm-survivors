import { array, boolean, number, object, text } from "../examples/survivors/host-values.mts"

export function parseJson(source: string): unknown {
  return JSON.parse(source)
}

function record<T>(value: unknown, parse: (entry: unknown) => T): Record<string, T> {
  return Object.fromEntries(Object.entries(object(value)).map(([key, entry]) => [key, parse(entry)]))
}

export function parseHosting(value: unknown) {
  const hosting = object(value)
  const staticConfig = hosting.static === undefined ? undefined : object(hosting.static)
  return {
    project_id: text(hosting.project_id),
    static:
      staticConfig === undefined
        ? undefined
        : { directory: staticConfig.directory === undefined ? undefined : text(staticConfig.directory) }
  }
}

export function parseReceipt(value: unknown) {
  const receipt = object(value)
  const build = object(receipt.build)
  return {
    schemaVersion: number(receipt.schemaVersion),
    siteProjectId: text(receipt.siteProjectId),
    commit: text(receipt.commit),
    branch: text(receipt.branch),
    sourceSnapshot: text(receipt.sourceSnapshot),
    sourceFingerprint: text(receipt.sourceFingerprint),
    sourceFiles: record(receipt.sourceFiles, (entry) => {
      const identity = object(entry)
      return { sha256: text(identity.sha256), mode: number(identity.mode) }
    }),
    files: record(receipt.files, text),
    dirty: boolean(receipt.dirty),
    dirtyFiles: array(receipt.dirtyFiles, text),
    build: { builtAt: text(build.builtAt) }
  }
}

export function parseVersion(value: unknown) {
  const version = object(value)
  return {
    revision: text(version.revision),
    branch: text(version.branch),
    sourceFingerprint: text(version.sourceFingerprint),
    dirty: boolean(version.dirty),
    builtAt: text(version.builtAt)
  }
}

export function parseDependency(value: unknown) {
  const dependency = object(value)
  return { ...dependency, bendVersion: text(dependency.bendVersion) }
}

export function parseAstroVersion(value: unknown): string | null {
  const manifest = object(value)
  if (manifest.dependencies === undefined) return null
  const dependencies = object(manifest.dependencies)
  if (dependencies.astro === undefined || dependencies.astro === null) return null
  return text(dependencies.astro) || null
}
