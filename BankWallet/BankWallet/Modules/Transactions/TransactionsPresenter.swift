import RxSwift

class TransactionsPresenter {
    private let interactor: ITransactionsInteractor
    private let router: ITransactionsRouter
    private let factory: ITransactionViewItemFactory
    private let loader: TransactionsLoader
    private let dataSource: TransactionsMetadataDataSource

    weak var view: ITransactionsView?
    var fucked = false
    var fuckedTwice = false
    let disposeBag = DisposeBag()
    let transactionHeight = 1457288

    init(interactor: ITransactionsInteractor, router: ITransactionsRouter, factory: ITransactionViewItemFactory, loader: TransactionsLoader, dataSource: TransactionsMetadataDataSource) {
        self.interactor = interactor
        self.router = router
        self.factory = factory
        self.loader = loader
        self.dataSource = dataSource
    }

}

extension TransactionsPresenter: ITransactionLoaderDelegate {

    func fetchRecords(fetchDataList: [FetchData]) {
        interactor.fetchRecords(fetchDataList: fetchDataList)
    }

    func didChangeData() {
//        print("Reload View")

        view?.reload()
    }

}

extension TransactionsPresenter: ITransactionsViewDelegate {

    func viewDidLoad() {
        interactor.initialFetch()

        fuckEmAll()
    }

    func onFilterSelect(coinCode: CoinCode?) {
        let coinCodes = coinCode.map { [$0] } ?? []
        interactor.set(selectedCoinCodes: coinCodes)
    }

    var itemsCount: Int {
        return loader.itemsCount
    }

    func item(forIndex index: Int) -> TransactionViewItem {
        let item = loader.item(forIndex: index)
        print("block height: \(item.record.blockHeight)")
        let lastBlockHeight = dataSource.lastBlockHeight(coinCode: item.coinCode)
        let threshold = dataSource.threshold(coinCode: item.coinCode)
        let rate = dataSource.rate(coinCode: item.coinCode, timestamp: item.record.timestamp)

        return factory.viewItem(fromItem: loader.item(forIndex: index), lastBlockHeight: lastBlockHeight, threshold: threshold, rate: rate)
    }

    func onBottomReached() {
        DispatchQueue.main.async {
//            print("On Bottom Reached")

            self.loader.loadNext()
        }
    }

    func onTransactionItemClick(index: Int) {
        router.openTransactionInfo(viewItem: item(forIndex: index))
    }

}

extension TransactionsPresenter: ITransactionsInteractorDelegate {

    func onUpdate(selectedCoinCodes: [CoinCode]) {
//        print("Selected Coin Codes Updated: \(selectedCoinCodes)")

        loader.set(coinCodes: selectedCoinCodes)
        loader.loadNext(initial: true)
    }

    func onUpdate(coinsData: [(CoinCode, Int, Int?)]) {
        var coinCodes = [CoinCode]()

        for (coinCode, threshold, lastBlockHeight) in coinsData {
            coinCodes.append(coinCode)
            dataSource.set(threshold: threshold, coinCode: coinCode)

            if let lastBlockHeight = lastBlockHeight {
                dataSource.set(lastBlockHeight: lastBlockHeight, coinCode: coinCode)
            }
        }

        interactor.fetchLastBlockHeights()

        if coinCodes.count < 2 {
            view?.show(filters: [])
        } else {
            view?.show(filters: [nil] + coinCodes)
        }

        loader.set(coinCodes: coinCodes)
        loader.loadNext(initial: true)
    }

    func onUpdateBaseCurrency() {
//        print("Base Currency Updated")

        dataSource.clearRates()
        view?.reload()

        fetchRates(recordsData: loader.allRecordsData)
    }

    func onUpdate(lastBlockHeight: Int, coinCode: CoinCode) {
//        print("Last Block Height Updated: \(coinCode) - \(lastBlockHeight)")

        dataSource.set(lastBlockHeight: lastBlockHeight, coinCode: coinCode)

        if let threshold = dataSource.threshold(coinCode: coinCode) {
            let indexes = loader.itemIndexes(coinCode: coinCode, lastBlockHeight: lastBlockHeight, threshold: threshold)

            if !indexes.isEmpty {
                view?.reload(indexes: indexes)
            }
        } else {
            view?.reload()
        }
    }

    func fuckEmAll() {
        if !fucked {
            print("fuckEmAll")
            let interval = Observable<Int>.interval(2, scheduler: MainScheduler.instance)
            interval.subscribe(onNext: { [weak self] _ in
                print("its time to start!!!!!!!!!!!")
                self?.fuck()
            }).disposed(by: disposeBag)
        }
        fucked = true
    }

    func fuck() {
        let tempLastHeight = fuckedTwice ? transactionHeight + 3 : transactionHeight
        fuckedTwice = !fuckedTwice
        onUpdate(lastBlockHeight: tempLastHeight, coinCode: "BTC")
    }

    func didUpdate(records: [TransactionRecord], coinCode: CoinCode) {
        loader.didUpdate(records: records, coinCode: coinCode)
        fetchRates(recordsData: [coinCode: records])
    }

    func didFetch(rateValue: Decimal, coinCode: CoinCode, currency: Currency, timestamp: Double) {
        //take here
        dataSource.set(rate: CurrencyValue(currency: currency, value: rateValue), coinCode: coinCode, timestamp: timestamp)

        let indexes = loader.itemIndexes(coinCode: coinCode, timestamp: timestamp)

        if !indexes.isEmpty {
            view?.reload(indexes: indexes)
        }
    }

    func didFetch(recordsData: [CoinCode: [TransactionRecord]]) {
//        print("Did Fetch Records: \(records.map { key, value -> String in "\(key) - \(value.count)" })")

        fetchRates(recordsData: recordsData)

        loader.didFetch(recordsData: recordsData)
    }

    private func fetchRates(recordsData: [CoinCode: [TransactionRecord]]) {
        var timestampsData = [CoinCode: [Double]]()

        for (coinCode, records) in recordsData {
            timestampsData[coinCode] = records.map { $0.timestamp }
        }

        interactor.fetchRates(timestampsData: timestampsData)
    }

}
