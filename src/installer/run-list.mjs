import { PACKAGE_NAME } from './constants.mjs'

/**
 * @param {unknown} value
 */
function assertStringArray(value) {
  if (!Array.isArray(value) || value.some((item) => typeof item !== 'string')) {
    throw new Error('Invalid releases payload: versions must be a string array.')
  }
}

/**
 * @param {unknown} value
 */
function assertStringRecord(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error('Invalid releases payload: dist-tags must be an object.')
  }

  for (const entry of Object.values(value)) {
    if (typeof entry !== 'string') {
      throw new Error('Invalid releases payload: dist-tags values must be strings.')
    }
  }
}

/**
 * @param {NodeJS.ProcessEnv} [env]
 */
function getReleaseMetadataFromEnv(env = process.env) {
  const raw = env.INSTALL_AZTEC_SKILLS_RELEASES_JSON
  if (!raw) {
    return null
  }

  let parsed
  try {
    parsed = JSON.parse(raw)
  } catch (error) {
    const message =
      error instanceof Error ? error.message : 'Unknown JSON parse error.'
    throw new Error(
      `INSTALL_AZTEC_SKILLS_RELEASES_JSON is not valid JSON: ${message}`,
    )
  }

  if (!parsed || typeof parsed !== 'object') {
    throw new Error('Invalid releases payload: expected object.')
  }

  const versions = parsed.versions
  const distTags = parsed['dist-tags']
  assertStringArray(versions)
  assertStringRecord(distTags)

  return { versions, distTags }
}

async function fetchReleaseMetadata() {
  const fromEnv = getReleaseMetadataFromEnv()
  if (fromEnv) {
    return fromEnv
  }

  const response = await fetch(`https://registry.npmjs.org/${PACKAGE_NAME}`)
  if (!response.ok) {
    throw new Error(
      `Failed to fetch release metadata for ${PACKAGE_NAME}: ${response.status} ${response.statusText}`,
    )
  }

  const payload = await response.json()
  const versions = Object.keys(payload.versions ?? {})
  const distTags = payload['dist-tags'] ?? {}

  return { versions, distTags }
}

export async function runList() {
  const { versions, distTags } = await fetchReleaseMetadata()
  const tagMap = new Map()

  for (const [tag, version] of Object.entries(distTags)) {
    const tags = tagMap.get(version) ?? []
    tags.push(tag)
    tagMap.set(version, tags)
  }

  const releases = [...versions].sort((a, b) =>
    b.localeCompare(a, undefined, { numeric: true }),
  )

  console.log(`Available ${PACKAGE_NAME} releases to install:\n`)

  if (Object.keys(distTags).length > 0) {
    console.log('Dist-tags:')
    console.table(
      Object.entries(distTags)
        .sort(([left], [right]) => left.localeCompare(right))
        .map(([tag, version]) => ({ tag, version })),
    )
  }

  console.log('Versions:')
  console.table(
    releases.map((version) => ({
      version,
      tags: (tagMap.get(version) ?? []).sort().join(', '),
    })),
  )
}
