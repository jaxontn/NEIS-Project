//+------------------------------------------------------------------+
//|                                                      NEIS_v2.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

//CONSTANT VARIABLE--------------------------
const int BUY = 35618414;
const int BUY_STOP = 50679423;
const int SELL = 14562057;
const int SELL_STOP = 54370812;
const int NONE = 97957279;
const int OVERBOUGHT = 64728598;
const int OVERSOLD = 10837256;
const int UPTREND = 57896376;
const int DOWNTREND = 10789387;
const int MINIMUM_CONFIRMATION = 4; //at least 4 confirmations
//-------------------------------------------


//GLOBAL VARIABLES---------------------------
datetime currentTime;
datetime previousTime;
bool hasNewCandle; //indicates whether a new candlestick has "started forming"
int TRADE_CANDLE_DELAY;
//-------------------------------------------

//TRADING ALGORITHM
/*
- A series of things that must be true/untrue before something happens.
- A series of indicators that MUST be true for me to enter a long/short trade.
- Avoid trading where the Big Banks trade (stay unpopular), avoid hotspots because
  there is where the Big Banks like to take things on the opposite where you
  intended
- Get me in and out of a trade at the best possible times
- BEFORE I TRADE, I HAVE TO KNOW HOW MUCH TO RISK FIRST! That's why I have to
  consult the ATR

PLEASE UNDERSTAND:
- There is no one indicator that is great at predicting where price will go.
  (you need a combination of indicators that confirm each other so you can
   really drill down in those absolute best times to go long or short)
- The ATR is the best, because it is the 1 indicator everyone should be using.
  (There is nothing sexy about this indicator)
- The ATR is crucial for Money Management
- Money Management is crucial to winning
*/

//Happens on Initialization of the Expert Advisor
int OnInit()
{
    Alert("Working");


    currentTime = iTime("EURUSD",PERIOD_M1,0);

    return(INIT_SUCCEEDED);
}






void OnDeinit(const int reason)
{
   
}






//Happens on every price tick
void OnTick()
{
  //Trade on the M5, not M1, M1 is only to look at M5 details at better details
    datetime incommingTime = iTime("EURUSD",PERIOD_M5,0);
    if( currentTime < incommingTime )//means new candlestick has "started forming"
    {
        previousTime = currentTime;
        currentTime = incommingTime;
        //Alert("New Time: " + currentTime);
        //Alert("Prev Time: " + previousTime);
    
        //sendIDDR();
        
        hasNewCandle = true;
    }

    if( hasNewCandle ) //Do something when have new candle forming
    {
        //EngulfingReversal( "EURUSD" );
        //bBand( "EURUSD" );
        myStrategy( "EURUSD" );
        hasNewCandle = false;
    }
}



 


//SEND Investor Detailed Digital Receipt to Telegram through HTTPS
void sendIDDR()
{
    string cookie = NULL, headers, message, telegram_url;
    char post[], result[];
    int res, timeout = 5000;
    
    //DATA TO PUT IN message
    int ticket, tradingCode, direction;
    double winProbability, loseProbability, risk, reward, lotSize, revenue, profit, totalProfit;
    datetime startDate, endDate;
    string symbol;


    message = "[New Time: " + currentTime + "]                       [Prev Time: " + previousTime + "]"; 
    //%0A means \n in telegram api, 
    //23 spaces == newline in mobile telegram view

    telegram_url = "https://api.telegram.org/bot1573581289:AAFkb4yJ0udgnzVfzdFhAsGkjLGgsObiPj0/sendMessage?chat_id=-1001348293243&text=";
    telegram_url = telegram_url + message;

    res = WebRequest("GET", telegram_url, cookie, NULL, timeout, post, 0, result, headers);
}



void sendTelegram( string msg )
{
    string cookie = NULL, headers, message, telegram_url;
    char post[], result[];
    int res, timeout = 5000;


    message = ": " + msg;

    telegram_url = "https://api.telegram.org/bot1573581289:AAFkb4yJ0udgnzVfzdFhAsGkjLGgsObiPj0/sendMessage?chat_id=-1001348293243&text=";
    telegram_url = telegram_url + message;

    res = WebRequest("GET", telegram_url, cookie, NULL, timeout, post, 0, result, headers);
}


void myStrategy( string symbol )
{ //Use Bollinger Band to buy and sell with multiple confirmations such as
  //1. engulfing patterns
  //2. trend
  //3. rsi
  //4. stochastic
    int confirmationNum = 0;

    //TO BUY
    if( bBand( symbol ) == BUY )
    {
        if( rsi( symbol ) == OVERSOLD && stochastic( symbol ) == OVERSOLD ) //RSI Confirmation
        {
             confirmationNum++;
            //   msg += "[rsi oversold] ";
        }

        //---------------------------------------------------------------------
        if( trend( symbol) == DOWNTREND && EngulfingReversal( symbol ) == BUY )
        {
            confirmationNum++;
            //   msg += "[downtrend] ";
        }
        else if( trend( symbol ) == UPTREND )
        {
            confirmationNum++;
        }
        //----------------------------------------------------------------------

        if( confirmationNum >= 1 )
        {
            ATR( symbol, BUY );
        }

    }
    else if( bBand( symbol ) == SELL ) //TO SELL
    {
        if( rsi( symbol ) == OVERBOUGHT && stochastic( symbol ) == OVERBOUGHT ) //RSI Confirmation
        {
            confirmationNum++;
            //   msg += "[rsi overbought] ";
        }

        //---------------------------------------------------------------------
        if( trend( symbol) == UPTREND && EngulfingReversal( symbol ) == SELL )
        {
            confirmationNum++;
            //   msg += "[uptrend] ";
        }
        else if( trend( symbol) == DOWNTREND )
        {
            confirmationNum++;
        }
        //---------------------------------------------------------------------

        if( confirmationNum >= 1 )
        {
            ATR( symbol, SELL );
        }
    }

}



//WE ARE TRADING IN M5, not M1. M1 is only to check more ni detail of the M5 decision

//Bollinger Band 
int bBand( string symbol )
{
    int signal;
    double lowerBB, upperBB, closedPrice;

    //Lower Band of the latest fully formed candlestick
    lowerBB = iBands( symbol, PERIOD_M5, 20, 2, 0, PRICE_MEDIAN, MODE_LOWER, 1);

    //Upper Band of the latest fully formed candlestick
    upperBB = iBands( symbol, PERIOD_M5, 20, 2, 0, PRICE_MEDIAN, MODE_UPPER, 1);

    //closed price of the latest fully formed candlestick
    closedPrice = iClose( symbol, PERIOD_M5, 1);

    //find out the position of the candle either at upper or lower band
    if( closedPrice >= upperBB ) //at upper band
    {
        //sell signal
        signal = SELL;
        //ATR( symbol, SELL ); //using ATR to execute trades
        
    }
    else if( closedPrice <= lowerBB ) //at lower band
    {
        //buy signal
        signal = BUY;
       // ATR( symbol, BUY ); //using ATR to execute trades
    }
    else
    {
        //no signal
        signal = NONE;
    }

    return signal;
}






//Double Candlestick PatterN
int EngulfingReversal( string symbol )
{
    int signal, confirmationNum;
    double secondCandleOpen, secondCandleClose, firstCandleOpen, firstCandleClose,
           thirdCandleClose, lowestLow;

    //first candle is the first candle in the engulfing pattern
    firstCandleOpen = iOpen( symbol, PERIOD_M5, 3 );
    firstCandleClose = iClose( symbol, PERIOD_M5, 3 );

    //second candle is the second candle in the engulfing pattern
    secondCandleOpen = iOpen( symbol, PERIOD_M5, 2 );
    secondCandleClose = iClose( symbol, PERIOD_M5, 2 );

    confirmationNum = 0;
 //   string msg = ""; //for testing
    signal = NONE;

    //Bullish Engulfing (Bullish)
    //first candle is bearish, second candle is bullish
    //shadows are not important
    //THE BULLISH ENGULFING IS THE MOST BULLISH OF ALL BULLISH REVERSAL PATTERNS

    //-------------RULES OF RECOGNITION------------------------------------------------------
    //STEP 1:
    //THE SECOND DAY'S REAL BODY MUST COMPLETELY ENGULFS THE FIRST DAY'S REAL BODY
    if( secondCandleOpen < firstCandleClose && secondCandleClose > firstCandleOpen)
    {
        //STEP 2: A [DOWNTREND] MUST BE IN PROGRESS.
        

        //STEP 3: THE FIRST DAY MUST BE A BLACK/RED CANDLE (close price < open price)
        if( firstCandleClose < firstCandleOpen )
        {
            //STEP 4: THE SECOND DAY MUST BE A WHITE/GREEN CANDLE (close price > open price)
            if( secondCandleClose > secondCandleOpen )
            {
                confirmationNum++; //Bullish Engulfing Confirmation
            //    msg += "[bullish engulfing] ";
                signal = BUY;
                //Proper action: Buy signal.
                //For agressive trader, no confirmation needed.
                //For conservative trader, bullish confirmation is sugested.

                //To confirm a buy:
                //1. the 3rd candle must close above the highest high of candles 1 and 2.
                thirdCandleClose = iClose( symbol, PERIOD_M5, 1 );

                if( thirdCandleClose > iHigh(symbol, PERIOD_M5, 2) && 
                    thirdCandleClose > iHigh(symbol, PERIOD_M5, 3) )
                {
                    //Best to buy if found at a low price area or when the market is oversold.
                    //Use RSI & Stochastics

                    

                    if( confirmationNum >= MINIMUM_CONFIRMATION ) //Make sure enough confirmation
                    {
                        signal = BUY;
                        //Firstly, INSTANT BUY
                        ATR( symbol, BUY ); //using ATR to execute trades

                        //find out the lowest low of candles 1 and 2
                        if( iLow(symbol, PERIOD_M5, 2) < iLow(symbol, PERIOD_M5, 3) )
                        {
                            lowestLow = iLow(symbol, PERIOD_M5, 2);
                        }
                        else if( iLow(symbol, PERIOD_M5, 2) > iLow(symbol, PERIOD_M5, 3) )
                        {
                            lowestLow = iLow(symbol, PERIOD_M5, 3);
                        }
                        //Next, Place sell-stop below the lowest low of candles 1 and 2.
                        ATR( symbol, SELL_STOP,  lowestLow );
                    }
                }
            }
        }
      //  sendTelegram( msg );
    }

    return signal;
}





/*int volatility()
{
   //low volatility might transition to higher volatility
   //high volatility might transition to lower volatility
}*/





int trend( string symbol )
{
    int signal;
    double starting, middle, last;
    starting = iMA( symbol, PERIOD_M5, 26, 0, MODE_EMA, PRICE_MEDIAN, 130);
    middle = iMA( symbol, PERIOD_M5, 26, 0, MODE_EMA, PRICE_MEDIAN, 65);
    last = iMA( symbol, PERIOD_M5, 26, 0, MODE_EMA, PRICE_MEDIAN, 1);

    signal = NONE;

    if( starting < middle && middle < last )
    {
        //a possible uptrend
        signal = UPTREND;
    }
    else if( starting > middle && middle > last )
    {
        //a possible downtrend
        signal = DOWNTREND;
    }
    return signal;
}




//to find whether price is OVERBOUGHT or OVERSOLD
int rsi( string symbol )
{
    int signal;
    double price;
    price = iRSI( symbol, PERIOD_M5, 14, PRICE_CLOSE, 1); //last fully formed candle

    signal = NONE;

    if( price >= 70 )
    {
        signal = OVERBOUGHT;
    }
    else if( price <= 30 )
    {
        signal = OVERSOLD;
    }
    return signal;
}




//to find whether price is OVERSOLD or OVERSOLD
int stochastic( string symbol )
{
    int signal;
    double price;
    price = iStochastic( symbol, PERIOD_M5, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 1 );
            //last fully formed candle

    signal = NONE;

    if( price >= 80 )
    {
        signal = OVERBOUGHT;
    }
    else if( price <= 20 )
    {
        signal = OVERSOLD;
    }
    return signal;
}









//USE THIS ON EVERY SINGLE TRADE [THE MOST IMPORTANT INDICATOR]
//PURPOSE: Money Management, Determining STOP LOSS, managing risk, finding pip value,
//         and executing trades.
void ATR(string symbol, int decision, double price = NULL )
{
    //Explanation of the ATR:
    /*
    - Tells you how many pips the currency pair has moved, on average, 
      in the past x amount of candles.
      Default Setting is 14 candles, that's it, the end.
    */
    
    /*The Way to describe it:
      - Not in units
      - Not in dollar amounts
      - How much much per pip are you trading? (your pip value)
      - E.g.: 1 lot on the EURUSD = $10 per pip*/
    /*
      ATR shows you the number of average pips for 14 candles
      e.g.:
      ATR(14)0.0125 means 125 pips
      ATR(14)0.0041 means 41 pips
      
      EUR/GBP              GBP/NZD
      -ATR = 41            -ATR = 125
      -Moves 1/3 of        -Moves 3X amount of
       GBP/NZD              EUR/GBP
      -For example, if     -Trade 1/3 less per pip
       you're trading at    ($2/pip)
       $6/pip
       
       [THIS IS MONEY MANAGEMENT]
       [YOU NEED TO TRADE ALL TRADES EQUALLY]
       
       KNOW THAT MONEY MANAGEMENT IS WHAT WILL SEPERATE YOU
       FROM THE LOSING TRADERS
       
       HAVE THE ATR ON YOUR CHART OR ON THE READY ALWAYS
       
       NEVER EVER TRADE WITHOUT IT!!!!!
    */      

    //Current ATR value
    double ATRValue, SLGap, TPGap, risk, pipValue, lotSize, sl, tp;

    if( (int)MarketInfo("EURUSD", MODE_DIGITS) == 3 ) //explain this
    {
        ATRValue = NormalizeDouble(iATR("EURUSD", PERIOD_M5, 14, 0), 2) * 100;
    }
    else if( (int)MarketInfo("EURUSD", MODE_DIGITS) == 5 )
    {
        ATRValue = NormalizeDouble(iATR("EURUSD", PERIOD_M5, 14, 0), 4) * 10000;
    }
    Alert("ATR: " + ATRValue);

    SLGap = ATRValue * 1.5; //number of SL pips away from current price
    Alert("SLGap: " + SLGap);
    TPGap = SLGap * 5; //number of TP pips away from current price
    risk = AccountBalance() * 0.02; //risk in USD of the account
    Alert("2% risk in USD: " + risk);
    pipValue = risk / SLGap;
    Alert("pipValue: " + pipValue);
    lotSize = calculateLotSize( SLGap );
    Alert("Lot size:" + lotSize );

    if( decision == BUY ) //instant buy
    {
        /*int  OrderSend(
   string   symbol,              // symbol
   int      cmd,                 // operation
   double   volume,              // volume
   double   price,               // price
   int      slippage,            // slippage
   double   stoploss,            // stop loss
   double   takeprofit,          // take profit
   string   comment=NULL,        // comment
   int      magic=0,             // magic number
   datetime expiration=0,        // pending order expiration
   color    arrow_color=clrNONE  // color
   );*/
       
        if( (int)MarketInfo("EURUSD", MODE_DIGITS) == 3 ) //explain this
        {
            sl = Ask - (SLGap / 100);
            tp = Ask + (TPGap / 100);
        }
        else if( (int)MarketInfo("EURUSD", MODE_DIGITS) == 5 )
        {
            sl = Ask - (SLGap / 10000);
            tp = Ask + (TPGap / 10000);
        }
        OrderSend( symbol, OP_BUY, lotSize, Ask, 3, sl, tp, "My order", 16384, 0, clrGreen);
        //execute a buy trade
    }
    else if( decision == SELL ) //instant sell
    {
        if( (int)MarketInfo("EURUSD", MODE_DIGITS) == 3 ) //explain this
        {
            sl = Bid + (SLGap / 100);
            tp = Bid - (TPGap / 100);
        }
        else if( (int)MarketInfo("EURUSD", MODE_DIGITS) == 5 )
        {
            sl = Bid + (SLGap / 10000);
            tp = Bid - (TPGap / 10000);
        }
        OrderSend( symbol, OP_SELL, lotSize, Bid, 3, sl, tp, "My order", 16384, 0, clrGreen);
        //execute a sell trade
    }
    else if( decision == BUY_STOP ) //buy-stop at a metioned price
    {
        if( (int)MarketInfo("EURUSD", MODE_DIGITS) == 3 ) //explain this
        {
            sl = price - (SLGap / 100);
            tp = price + (TPGap / 100);
        }
        else if( (int)MarketInfo("EURUSD", MODE_DIGITS) == 5 )
        {
            sl = price - (SLGap / 10000);
            tp = price + (TPGap / 10000);
        }
        OrderSend( symbol, OP_BUYSTOP, lotSize, price, 3, sl, tp, "My order", 16384, 0, clrGreen);
       //execute a buy-stop
    }
    else if( decision == SELL_STOP ) //sell-stop at a mentioned price
    {
        if( (int)MarketInfo("EURUSD", MODE_DIGITS) == 3 ) //explain this
        {
            sl = price + (SLGap / 100);
            tp = price - (TPGap / 100);
        }
        else if( (int)MarketInfo("EURUSD", MODE_DIGITS) == 5 )
        {
            sl = price + (SLGap / 10000);
            tp = price - (TPGap / 10000);
        }
        OrderSend( symbol, OP_SELLSTOP, lotSize, price, 3, sl, tp, "My order", 16384, 0, clrGreen);
        //execute a sell-stop
    }
    else if( decision == NONE )
    {
        //execute nothing
    }
}




//PURPOSE: To calculate the lot size
double calculateLotSize( double SL )
{
    double maxRiskPerTrade = 1; //% of balance to risk in one trade
    double lotSize = 0; 
    //get the value of a tick
    double nTickValue = MarketInfo("EURUSD", MODE_TICKVALUE);

    //if the digits are 3 or 5, we normalize multiplying by 10.
    if(((int)MarketInfo("EURUSD", MODE_DIGITS) == 3) || ((int)MarketInfo("EURUSD", MODE_DIGITS) == 5))
    {
        nTickValue = nTickValue * 10;
    }

    //we apply the formula to calculate the position size and assign the value to the variable.
    lotSize = (AccountBalance() * maxRiskPerTrade / 100) / (SL * nTickValue);
    lotSize = MathRound(lotSize / MarketInfo("EURUSD", MODE_LOTSTEP)) * MarketInfo("EURUSD", MODE_LOTSTEP);

    return lotSize;
}





/*void fundSecurity()
{
  //dont "lose" more than 2% a day
  //dont "lose" more than 10% for a lifetime
}*/

//MONEY MANAGEMENT
/*The Big 3: [YOU MUST CARE ABOUT ALL THE BIG 3]
  1. Money Management [STEP 1]
  2. Trade Psychology [STEP 2]
  3. Trade Entries    [STEP 3]

Know: 1. What to risk(% fo account)
      2. How many pips to risk
      3. Managing a trade
      4. The indicators involved

No Money Management = NO MONEY
*/


/*ABOUT RISK--------------------------------------------------------
- Dangers of bad risk
- The magic number
- How to use the ATR to figure out your risk
- How many trades can you have open?
- You can still screw this up!
- The 99% of forex traders that either lose money, break even, or
  just make enough to barely keep it going but not enough to
  trade at pro level or save for their retirement.

- We must get you out of the 99%
- SHIT The 99% Does:
  # No set risk
  # Wildly increase/decrease depending on bad reasoning
  # Feel the need to increase risk after their account goes way down.
    [REALLY DANGEROUS SLOP TO GO DOWN]
  # No understanding of (end of video)

IF $50K down to 40K, you need 25% Return to breakeven
IF $50K down to 25K, you need 100% Return to breakeven [to go back to initial deposit]
Even professional traders takes around 3 to 4 years just to get back 100% of initial
deposit.
[GETTING DOWN TO THIS LEVEL IS TRADING SUICIDE]
[AND ALSO! NOTHING FAVORS THE TIMID AT ALL]
- Too low risk makes your trading not worth it
- The most successful people in the world take lots of risks.
  The BIG difference is, they know how to manage risk better than
  anyone else
  -Their risk are not reckless, they are taking good risks and MINIMISE
   the chance of failure.



MAGIC NUMBER [what % of your trading account should you be risking on every single
              trade you make?]
- Risk 2% of your entire trading account on every trade.
  [But is not always that simple, there are rules to follow behind this]
- 2% risk = 2% is the MOST you can lose on a trade.
- I will show you how to calculate this
- GOOD NEWS: When you lose, you usually wont lose 2%!!

WE ARE GOING TO USE THE ATR
- It is how many pips, top to bottom a currency pair moves per candle, on average
- It takes the previous 14 candles and makes an average of it
- 1.5X the ATR for a currency pair
- Your SL should be 1.5X the ATR away from where price is now.
- This is how you determine where your STOP LOSS goes.
- Your support does not goes with some support or resistance line, or on fibonacci level
  ,NO, just do it this way and you will always know where to put it! Ignore everything else



ATR To Find Pip value
# Find out what 2% of your account is. Call this your [RISK]
# Figure out 1.5X ATR of the currency pair actually is 
  (this is where you gonna put your stop loss)
# Formula: RISK / 1.5ATR = Pip Value
  (This is gonna tell you how many dollars per pip you need to put on this trade)
  [FOR EVERY SINGLE TRADE]


GOOD NEWS
# I rarely have my stop loss hit
# Find an indicator that gets you out of bad trades before this happens
# I call them Exit Indicators


WARNING!!!!
HOW TO Over-leverage [the trap]
- Do NOT trade the same currency more than once at 2% risk
e.g.
[DONT DO THIS]
EUR/USD short, AUD/USD short, USE/JPY long all at 2% risk each.
#IN TOTAL YOU HAVE 6% OF YOUR TRADE ON THE USD!!
#if anything were to go sideways with the USD DOLLAR or if the Big Bank just
 woke up to take the USD Dollar short, you are in BIG TROUBLE, you might have
 3 trades that all hit Stop Loss.
 It can put an iriversible dent into your trading account


HOW NOT TO Over-leverage [the right way]
- Go with the first trade entry for that currency and ride it.
  If there are multiple entries for the same currency, e.g.
  EUR/JPY, EUR/NZD, just choose one
- OR go half/half (1% and 1%)

[NEVER FEAR RISK, BUT ALWAYS BE SMART ABOUT IT!]
[BE CONSISTENT HERE]
[KNOW THE CALCULATIONS]
[FIND AN EXIT INDICATOR]
[DON'T FALL INTO THE OVER-LEVERAGE TRAP]
--------------------------------------------------------------------*/



/*ALGORITHM (System)
1) ATR
2) 
3) Confirmation Indicator (to either go long or short)
4) 
5) 
6) Exit Indicator (makes sure it doesn't get you out too soon,
                   but also makes sure your stop loss doesn't
                   get hit)
   [This is how you take risk, and minimize risk at the same time]
*/ 




/*SHOULD I PAY FOR INDICATORS?
Most indicators are rubbish, you just need to find your own edge.
Create your own best indicator.
*/