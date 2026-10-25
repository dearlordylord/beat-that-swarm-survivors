import { errorMessage } from "../examples/survivors/host-values.mts"
import { prepareSite, argumentsFor } from "./survivors-publication.mts"
try {
  console.log(JSON.stringify(await prepareSite(argumentsFor(process.argv.slice(2))), null, 2))
} catch (error) {
  console.error(errorMessage(error))
  process.exitCode = 1
}
