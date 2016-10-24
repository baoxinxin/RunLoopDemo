//
//  ViewController.swift
//  RunLoopDemo
//
//  Created by ZLY on 16/10/24.
//  Copyright © 2016年 BX. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
   
    var myThread: Thread?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        runLoopInMainThread()
//        runLoopWithGCD()
        
//        tryPerformSelectorOnMainThread()
//        tryPerformSelectorOnBackGroundThread()
        
//        alwaysLiveBackGroundThread()
        
//        tryTimeOnMainThread()
//        tryTimeOnBackGroundThread()
        gcdTimer()
        
//        runLoopAddDependance()
    }
    
    //MARK: -  //runloop想要工作，必须存在一个Item(source,observer,timer)
    func runLoopInMainThread() {
        while true {
            print("while begin")
            let runloop = RunLoop.current
            runloop.run(mode: .defaultRunLoopMode, before: Date.distantFuture)
            print("while end")
            print(runloop)
        }
    }
    
    // 在GCD中实现上个方法相同的效果
    func runLoopWithGCD() {
        while true {
            print("while begin")
            let runloop = RunLoop.current
            let macPort = Port.init()
            runloop.add(macPort, forMode: .defaultRunLoopMode)
            runloop.run(mode: .defaultRunLoopMode, before: Date.distantFuture)
            print("while end")
            print(runloop)
        }
    }
    
    //MARK:- 深入理解Perform Selector
    func tryPerformSelectorOnMainThread(){
        self.perform(#selector(ViewController.MainThreadMethod))
    }
    
    func MainThreadMethod()  {
        print("execute ", #function)
    }
    
    func tryPerformSelectorOnBackGroundThread() {
        //GCD在Swift3.0已经更Swift化
        //获取一个全局对列并全局队列异步
        DispatchQueue.global().async {
            self.perform(#selector(ViewController.backGroundThread), on: Thread.current, with: nil, waitUntilDone: false)
            //perform(<#T##aSelector: Selector##Selector#>, on: <#T##Thread#>, with: <#T##Any?#>, waitUntilDone: <#T##Bool#>) 此时系统创建一个Timer的source，加到对应的RunLoop上去
            let runloop = RunLoop.current
            runloop.run()
        }
    }
    
    func backGroundThread() {
        print("execute %s", #function)
    }
    
    //MARK:- 一直“活着”的后台线程 点击屏幕时，让子线程做任务
    func alwaysLiveBackGroundThread() {
        let thread = Thread(target: self, selector: #selector(ViewController.myThreadRun), object: nil)
        self.myThread = thread
        self.myThread?.start()
    }
    
    func myThreadRun() {
        print("my thread run")
        RunLoop.current.add(Port.init(), forMode: .defaultRunLoopMode)
        RunLoop.current.run()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(self.myThread)
        //线程在执行完任务之后死亡了，为阻止死亡添加runloop
        self.perform(#selector(ViewController.doBackGroundThreadWork), on: self.myThread!, with: nil, waitUntilDone: true)
    }
    
    func doBackGroundThreadWork() {
        print("do some work ", #function)
    }
    
    //MARK: - 深入理解NSTimer
    func tryTimeOnMainThread() {
        let myTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(ViewController.timerAction), userInfo: nil, repeats: true)
        //fire立即触发改定时器
        myTimer.fire()
    }
    
    func timerAction() {
        print("timer action")
    }
    
    func tryTimeOnBackGroundThread() {
        DispatchQueue.global().async {
            let myTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(ViewController.timerAction), userInfo: nil, repeats: true)
            myTimer.fire()
            //创建一次时效，需要开启runloop;Timer需要注册到RunLoop中才能生效
            let runloop = RunLoop.current
            runloop.run()
            //当在改线程执行一个耗时操作时，runloop为了节省资源，并不会在非常准确的时间点调用这个Timer，造成误差（Timer有个冗余度tolerance，容许有多少最大误差）。
            //GCD可以实现定时器的效果，由于和runloop没有关联，更精确
        }
    }
    
    //GCD定时器的实现
    func gcdTimer() {
        //全局队列
        var count = 0
        let queue = DispatchQueue.global()
        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue)
        timer.setEventHandler { 
            print("count = ", count)
            count += 1
            if count > 5 {
                timer.cancel()
            }
        }
        timer.scheduleOneshot(deadline: .now())
//        timer.scheduleRepeating(deadline: .now(), interval:  .seconds(1), leeway: . milliseconds(100))
        timer.resume()
        //在调用DispatchSourceTimer时，无论设置timer.scheduleOneShot还是        timer.scheduleRepeating必须调用cancle()
    }
    
    //MARK:- 让两个后台线程有依赖性的一种方式 runloop实现
    //一个线程工作完后唤醒另一线程
    func runLoopAddDependance() {
        print("start a new run loop thread")
        let runLoopThread = Thread(target: self, selector: #selector(ViewController.handleRunLoopThreadTask), object: nil)
        runLoopThread.start()
        
        print("Exit handleRunLoopThreadButtonTouchUpInside")
        DispatchQueue.global().async {
              self.myThread = Thread.current
                print("begin runloop")
                let runloop = RunLoop.current
                let myPort = Port.init()
                runloop.add(myPort, forMode: .defaultRunLoopMode)
                runloop.run(mode: .defaultRunLoopMode, before: Date.distantFuture)
                print("end runloop")
                self.myThread?.cancel()
                self.myThread = nil
        }
        
    }
    
    func handleRunLoopThreadTask() {
        print("enter run loop thread")
        for i in 0..<5 {
            print("in run loop thread, count = ", i)
            sleep(UInt32(i))
        }
        //通过selector方法唤醒runloop
        self.perform(#selector(ViewController.tryOnThread), on: self.myThread!, with: nil, waitUntilDone: false)
    }
    
    func tryOnThread() {
        print("唤醒runloop")
    }
    
   
    
}


//单例的使用
//1.最丑陋的方法(Swift皮，OC心)
//class Singleton1 {
//    class var shareInstance: Singleton1 {
//        struct Static {
//            static var onceToken: dispatch_once_t = 0
//            static var instance: Singleton1? = nil
//        }
//        dispatch_once(&Static.onceToken) {
//            Static.instance = Singleton1()
//        }
//        return Static.instance!
//    }
//}

//2.结构体方法("新瓶装老酒") Swift1.0不支持静态类变量，但在结构体中支持
class Singleton2 {
    class var sharedInstance: Singleton2 {
        struct Static {
            static let instance = Singleton2()
        }
        return Static.instance
    }
}

//3.全局变量方法("单行单例") Swift1.2后有了访问权限功能和静态类成员
//”全局变量（还有结构体和枚举体的静态成员）的Lazy初始化方法会在其被访问的时候调用一次。类似于调用'dispatch_once'以保证其初始化的原子性。这样就有了一种很酷的'单次调用'方式：只声明一个全局变量和私有的初始化方法即可。全局变量和结构体／枚举体的静态成员是支持”dispatch_once”特性的
private let sharedKraken = Singleton3()
class Singleton3 {
    class var sharedInstance: Singleton3 {
        return sharedKraken
    }
}

//4.静态变量
class Singleton4 {
    static let sharedInstance = Singleton4()
}
