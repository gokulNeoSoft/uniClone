const factoryContract = artifacts.require('Factory')
const router = artifacts.require('Router')
const Gtoken = artifacts.require('Gtoken')
const Stoken = artifacts.require('Stoken')
const { expect } = require('chai')
const chai = require('chai')
const truffleAssert = require('truffle-assertions')
contract('Factory', async (accounts) => {
  var [user1, user2] = accounts;
  var _factoryContract;
  var _routerContract;
  var _token1;
  var _token2;
  var zero_address = '0x0000000000000000000000000000000000000000'

  beforeEach(async () => {
    _factoryContract = await factoryContract.new();
    _routerContract = await router.new(_factoryContract.address);
    _token1 = await Gtoken.new();
    _token2 = await Stoken.new();
  })

  describe('Full exchange process test : ', async function () {
    it('0.Checking deployed contracts',async function(){
        var userBalOFA = await _token1.balanceOf(user1);
        var userBalOFB = await _token2.balanceOf(user1);
        assert.equal(userBalOFA.toString(), '50000000000000000000');
        assert.equal(userBalOFB.toString(), '50000000000000000000');
    })

    it('1.Adding liquidity', async function () {
      await truffleAssert.reverts(
        _factoryContract.createPairs(_token1.address, _token2.address),
        'ROUTER ADDRESS NOT SET.',
      )
      await _factoryContract.setRouterAddress(_routerContract.address)
      await _factoryContract.createPairs(_token1.address, _token2.address)
      var pairAddress = await _factoryContract.getPair(
        _token1.address,
        _token2.address,
      )
      assert.notEqual(pairAddress, zero_address)
      await _token1.approveSpender(_routerContract.address, 50)
      await _token2.approveSpender(_routerContract.address, 50)
      await _routerContract._addLiquidity(
        _token1.address,
        _token2.address,
        5,
        20,
        1,
        1,
      )
      var res = await _routerContract.getReserve(
        _token1.address,
        _token2.address,
      )
      assert.equal(res.amountA.toString(), '5000000000000000000')
      assert.equal(res.amountB.toString(), '20000000000000000000')
    })

    it('2.Exchange Tokens', async function () {
      await _factoryContract.setRouterAddress(_routerContract.address)
      await _factoryContract.createPairs(_token1.address, _token2.address)
      await _token1.approveSpender(_routerContract.address, 50)
      await _token2.approveSpender(_routerContract.address, 50)
      await _routerContract._addLiquidity(
        _token1.address,
        _token2.address,
        5,
        20,
        1,
        1,
      )
      await _token1.mint(user2, 50)
      await _token1.approveSpender(_routerContract.address, 50, { from: user2 })
      await _routerContract._swapExactTokensAtoB(
        _token1.address,
        _token2.address,
        1,
        { from: user2 },
      )
      var res = await _routerContract.getReserve(
        _token1.address,
        _token2.address,
      )
      assert.equal(res.amountA.toString(), '6000000000000000000')
      assert.equal(res.amountB.toString(), '16675004168751042187')
    })

    it('3.Remove liquidity', async function () {
        await _factoryContract.setRouterAddress(_routerContract.address)
        await _factoryContract.createPairs(_token1.address, _token2.address)
        await _token1.approveSpender(_routerContract.address, 50)
        await _token2.approveSpender(_routerContract.address, 50)
        await _routerContract._addLiquidity(
          _token1.address,
          _token2.address,
          5,
          20,
          1,
          1,
        )
        await _token1.mint(user2, 50)
        await _token1.approveSpender(_routerContract.address, 50, { from: user2 })
        await _routerContract._swapExactTokensAtoB(
          _token1.address,
          _token2.address,
          1,
          { from: user2 },
        );
        await _routerContract._removeLiquidity(_token1.address, _token2.address);
        var userBalOFA = await _token1.balanceOf(user1);
        var userBalOFB = await _token2.balanceOf(user1);
        assert.equal(userBalOFA.toString(), '51000000000000000000');
        assert.equal(userBalOFB.toString(), '46675004168751042187');
        var res = await _routerContract.getReserve(
            _token1.address,
            _token2.address,
        )
        assert.equal(res.amountA.toString(), '0');
        assert.equal(res.amountB.toString(), '0');
      })
  })
  
})
