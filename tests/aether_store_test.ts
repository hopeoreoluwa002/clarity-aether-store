import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure product listing works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const block = chain.mineBlock([
      Tx.contractCall('aether-store', 'list-product',
        [types.ascii("Test Product"), types.uint(1000000), types.uint(10)],
        deployer.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
    
    const response = chain.callReadOnlyFn(
      'aether-store',
      'get-product',
      [types.uint(1)],
      deployer.address
    );
    response.result.expectOk().expectSome();
  }
});

Clarinet.test({
  name: "Test purchase flow",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const buyer = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('aether-store', 'list-product',
        [types.ascii("Test Product"), types.uint(1000000), types.uint(1)],
        deployer.address
      )
    ]);
    
    block = chain.mineBlock([
      Tx.contractCall('aether-store', 'purchase-product',
        [types.uint(1)],
        buyer.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectUint(1);
    
    const response = chain.callReadOnlyFn(
      'aether-store',
      'get-order',
      [types.uint(1)],
      deployer.address
    );
    response.result.expectOk().expectSome();
  }
});

Clarinet.test({
  name: "Test seller rating system",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const buyer = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('aether-store', 'rate-seller',
        [types.principal(deployer.address), types.uint(5)],
        buyer.address
      )
    ]);
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
    
    const response = chain.callReadOnlyFn(
      'aether-store',
      'get-seller-rating',
      [types.principal(deployer.address)],
      deployer.address
    );
    response.result.expectOk().expectUint(5);
  }
});
