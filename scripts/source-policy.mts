export default {
  meta: { name: "source-policy" },
  rules: {
    "no-authored-javascript": {
      create(context: { report(diagnostic: { message: string; loc: { line: number; column: number } }): void }) {
        return {
          Program() {
            context.report({
              message: "Author source in TypeScript. JavaScript belongs in generated build directories.",
              loc: { line: 1, column: 0 }
            })
          }
        }
      }
    }
  }
}
