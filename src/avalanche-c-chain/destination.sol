// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/exchange-contracts/contracts/pangolin-periphery/interfaces/IPangolinRouter.sol";
import "../../lib/exchange-contracts/contracts/pangolin-core/interfaces/IPangolinPair.sol";
import "../../lib/reactive-lib/src/abstract-base/AbstractCallback.sol";

struct Reserves {
    uint112 reserve0;
    uint112 reserve1;
}

contract PangolinDemoStopOrderCallback is AbstractCallback {
    event Stop(
        address indexed pair,
        address indexed client,
        address indexed token,
        uint256[] tokens
    );
    
    event AvaxRefunded(
        address indexed client,
        uint256 amount
    );

    IPangolinRouter private router;
    uint private constant DEADLINE = 2707391655;

    constructor(address _callback_sender, address _router) AbstractCallback(_callback_sender) payable {
        router = IPangolinRouter(_router);
    }

    function stop(
        address /* sender */,
        address pair,
        address client,
        bool is_token0,
        uint256 coefficient,
        uint256 threshold
    ) external authorizedSenderOnly {
        address token0 = IPangolinPair(pair).token0();
        address token1 = IPangolinPair(pair).token1();
        (uint112 reserve0, uint112 reserve1, ) = IPangolinPair(pair).getReserves();
        require(below_threshold(is_token0, Reserves({ reserve0: reserve0, reserve1: reserve1 }), coefficient, threshold), 'Rate above threshold');
        
        address token_sell = is_token0 ? token0 : token1;
        address token_buy = is_token0 ? token1 : token0;
        
        uint256 allowance = IERC20(token_sell).allowance(client, address(this));
        require(allowance > 0, 'No allowance');
        require(IERC20(token_sell).balanceOf(client) >= allowance, 'Insufficient funds');
        
        assert(IERC20(token_sell).transferFrom(client, address(this), allowance));
        assert(IERC20(token_sell).approve(address(router), allowance));
        
        address[] memory path = new address[](2);
        path[0] = token_sell;
        path[1] = token_buy;
        
        uint256[] memory tokens = router.swapExactTokensForTokens(
            allowance, 
            0, 
            path, 
            address(this), 
            DEADLINE
        );
        
        assert(IERC20(token_buy).transfer(client, tokens[1]));
        
        emit Stop(pair, client, token_sell, tokens);
        
        // Refund remaining AVAX to client after order execution
        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            (bool success, ) = payable(client).call{value: remainingBalance}("");
            require(success, "AVAX refund failed");
            emit AvaxRefunded(client, remainingBalance);
        }
    }

    function below_threshold(bool token0, Reserves memory sync, uint256 coefficient, uint256 threshold) internal pure returns (bool) {
        if (token0) {
            return (sync.reserve1 * coefficient) / sync.reserve0 <= threshold;
        } else {
            return (sync.reserve0 * coefficient) / sync.reserve1 <= threshold;
        }
    }
}