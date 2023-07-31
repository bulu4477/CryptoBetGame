# CryptoBetGame 
游戏规则
------
player1发送一定数量的BNB，创建游戏，player2发送一定数量的BNB并且根据游戏ID加入游戏，在双方都加入游戏后，由随机值决定获胜者，获胜者拿走双方下注的所有BNB，双方不同的下注数量决定了获胜概率，比如player1下注了10 BNB，player2下注了90 BNB，那么player1的获胜概率为10/(10+90)=10%。
<br>随机数算法没有采用chainlink的VRF，因为延迟过高，而是使用双方地址和下注数量决定随机值。<br>

---
前端部分todo
---
