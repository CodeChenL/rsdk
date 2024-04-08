local product_data = import "../../../lib/product_data.libjsonnet";

function(
    product,
    variant,
) std.manifestYamlDoc(
    {
        name: "Build image for %(variant)s channel" % {variant: variant},
        on: {
            workflow_dispatch: {}
        },
        env: {
            GH_TOKEN: "${{ github.token }}"
        },
        jobs: {
            prepare_release:{
                "runs-on": "ubuntu-latest",
                steps: [
                    {
                        name: "Checkout",
                        uses: "actions/checkout@v4"
                    },
                    {
                        name: "Generate changelog",
                        uses: "radxa-repo/rbuild-changelog@main",
                        with: {
                            product: product
                        }
                    },
                    {
                        name: "Query product info",
                        id: "query",
                        uses: "RadxaOS-SDK/rsdk/.github/actions/query@main",
                        with: {
                            product: product
                        }
                    },
                    {
                        name: "Create empty release",
                        id: "release",
                        uses: "softprops/action-gh-release@v2",
                        with: {
                            token: "${{ secrets.GITHUB_TOKEN }}",
                            target_commitish: "main",
                            draft: false,
                            prerelease: true,
                            files: ".changelog/changelog.md",
                        } + if variant == "release"
                        then
                            {
                                tag_name: "b${{ github.run_number }}",
                                body_path: "README.md",
                            }
                        else if variant == "test"
                        then
                            {
                                tag_name: "t${{ github.run_number }}",
                                body: "This is a test build for internal development.\nOnly use when specifically instructed by Radxa support.\n",
                            }
                        else
                            {},
                    }
                ],
                outputs: {
                    release_id: "${{ steps.release.outputs.id }}",
                    suites: "${{ steps.query.outputs.suites }}",
                    editions: "${{ steps.query.outputs.editions }}",
                }
            },
            build: {
                "runs-on": "ubuntu-latest",
                needs: "prepare_release",
                strategy: {
                    matrix:{
                        product: [ product ],
                        suite: "${{ fromJSON(needs.prepare_release.outputs.suites )}}",
                        edition: "${{ fromJSON(needs.prepare_release.outputs.editions )}}",
                    }
                },
                steps: [
                    {
                        name: "Checkout",
                        uses: "actions/checkout@v4"
                    },
                    {
                        name: "Build image",
                        uses: "RadxaOS-SDK/rsdk/.github/actions/build@main",
                        with: {
                            product: "${{ matrix.product }}",
                            suite: "${{ matrix.suite }}",
                            edition: "${{ matrix.edition }}",
                            "release-id": "${{ needs.prepare_release.outputs.release_id }}",
                            "github-token": "${{ secrets.GITHUB_TOKEN }}",
                        } + if variant == "test"
                        then
                            {
                                "test-repo": true,
                                timestamp: "t${{ github.run_number }}",
                            }
                        else
                            {},
                    }
                ]
            }
        }
    },
    quote_keys=false
)