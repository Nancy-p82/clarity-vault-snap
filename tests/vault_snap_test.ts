import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test storing new image metadata",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const imageHash = "QmHash123456789";
    const imageSize = 1000;

    let block = chain.mineBlock([
      Tx.contractCall(
        'vault-snap',
        'store-image',
        [types.ascii(imageHash), types.uint(imageSize)],
        deployer.address
      )
    ]);

    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);

    // Verify stored data
    const result = chain.callReadOnlyFn(
      'vault-snap',
      'get-image-data',
      [types.ascii(imageHash)],
      deployer.address
    );
    result.result.expectOk();
  }
});

Clarinet.test({
  name: "Test ownership verification",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const imageHash = "QmHash123456789";
    const imageSize = 1000;

    // Store image
    let block = chain.mineBlock([
      Tx.contractCall(
        'vault-snap',
        'store-image',
        [types.ascii(imageHash), types.uint(imageSize)],
        deployer.address
      )
    ]);

    // Verify correct owner
    let result = chain.callReadOnlyFn(
      'vault-snap',
      'verify-ownership',
      [types.ascii(imageHash), types.principal(deployer.address)],
      deployer.address
    );
    result.result.expectOk().expectBool(true);

    // Verify incorrect owner
    result = chain.callReadOnlyFn(
      'vault-snap',
      'verify-ownership',
      [types.ascii(imageHash), types.principal(wallet1.address)],
      deployer.address
    );
    result.result.expectOk().expectBool(false);
  }
});

Clarinet.test({
  name: "Test image deletion",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    const imageHash = "QmHash123456789";
    const imageSize = 1000;

    // Store image
    let block = chain.mineBlock([
      Tx.contractCall(
        'vault-snap',
        'store-image',
        [types.ascii(imageHash), types.uint(imageSize)],
        deployer.address
      )
    ]);

    // Try deleting as non-owner (should fail)
    block = chain.mineBlock([
      Tx.contractCall(
        'vault-snap',
        'delete-image',
        [types.ascii(imageHash)],
        wallet1.address
      )
    ]);
    block.receipts[0].result.expectErr().expectUint(100);

    // Delete as owner
    block = chain.mineBlock([
      Tx.contractCall(
        'vault-snap',
        'delete-image',
        [types.ascii(imageHash)],
        deployer.address
      )
    ]);
    block.receipts[0].result.expectOk().expectBool(true);
  }
});
