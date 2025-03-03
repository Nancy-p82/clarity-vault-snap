// [Previous test content remains unchanged, adding new tests below]

Clarinet.test({
  name: "Test user storage limits",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const imageSize = max-image-size + 1;
    
    // Test image size limit
    let block = chain.mineBlock([
      Tx.contractCall(
        'vault-snap',
        'store-image',
        [types.ascii("QmTooBig"), types.uint(imageSize)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(104);
    
    // Test user stats
    const result = chain.callReadOnlyFn(
      'vault-snap',
      'get-user-stats',
      [types.principal(deployer.address)],
      deployer.address
    );
    result.result.expectOk();
  }
});
