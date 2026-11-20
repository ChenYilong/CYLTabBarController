package com.cyl.tabbar

import com.cyl.tabbar.CYLTabBarConfiguration.CYLTabBarConfigurationError
import java.util.concurrent.ConcurrentHashMap

// MARK: - Remote configuration interfaces 远程配置接口
//
// [EN] The library's own configuration (the file that initializes the tab bar) is always what the tab bar is built from.
//      A remote configuration service (Firebase Remote Config today, others later) only delivers values; the code below
//      is programmed to interfaces, so a service is added without touching the tab bar:
//        CYLRemoteConfigSource  fetches raw values from a service (the optional adapter of a service implements it);
//        CYLRemoteConfigMapper  maps what a service delivered into the library's configuration dictionary, the same
//                               dictionary every file format gives (the "CYLUtils" layer of docs/Configuration-File.md);
//        CYLRemoteConfigLoader  the fetch policy: the defaults first, the fetched values over them, never a broken tab bar.
//      The configuration file format follows Firebase Remote Config's design as closely as possible (a parameter is a key
//      with a default value and a value type), so a mapper has little to do; it never depends on Firebase.
// [CN] 本库自己的配置（初始化 TabBar 的文件）始终是构建 TabBar 的依据。远程配置服务（目前是 Firebase Remote Config，以后会有其他服务）只负责下发值；
//      下面的代码面向接口编程，增加一个服务无需修改 TabBar：
//        CYLRemoteConfigSource  从服务拉取原始值（服务的可选适配器实现它）；
//        CYLRemoteConfigMapper  把服务下发的内容映射为本库的配置字典，即各种文件格式给出的同一种字典（docs/Configuration-File.md 中的 “CYLUtils” 层）；
//        CYLRemoteConfigLoader  拉取策略：先用默认值，拉取到的值覆盖其上，永远不会得到坏掉的 TabBar。
//      配置文件格式尽可能与 Firebase Remote Config 的设计一一对应（参数是带默认值与值类型的 key），因此映射器需要做的事很少；它从不依赖 Firebase。

/**
 * [EN] The value types of a Remote Config parameter, as the template names them (`valueType`).
 * [CN] Remote Config 参数的值类型，与模板中的 `valueType` 同名。
 */
enum class CYLRemoteConfigValueType {
    STRING, NUMBER, BOOLEAN, JSON;

    companion object {
        /**
         * [EN] The type a template or a service names ("STRING", "NUMBER", "BOOLEAN", "JSON"; case-insensitive), or null.
         * [CN] 模板或服务给出的类型名称（"STRING"、"NUMBER"、"BOOLEAN"、"JSON"，不区分大小写），否则为 null。
         */
        @JvmStatic
        fun of(name: String?): CYLRemoteConfigValueType? = values().firstOrNull { it.name.equals(name?.trim(), ignoreCase = true) }
    }
}

/**
 * [EN] What a remote configuration service delivered: the service's identifier, the values by key (strings, as the Firebase
 *      SDKs give them; numbers and booleans are accepted), and the value type of each key when the service names one.
 * [CN] 远程配置服务下发的内容：服务标识、按 key 的值（字符串，与 Firebase SDK 给出的相同；也接受数字与布尔值），以及服务给出的每个 key 的值类型。
 */
data class CYLRemoteConfigPayload(
    val sourceIdentifier: String,
    val values: Map<String, Any?>,
    val valueTypes: Map<String, CYLRemoteConfigValueType> = emptyMap(),
)

/**
 * [EN] A remote configuration service: fetches its values. The Firebase adapter, or any other service's, implements this;
 *      the core never links a service SDK. `completion` runs on the thread the service completes on, exactly once.
 * [CN] 远程配置服务：拉取其值。Firebase 适配器或其他服务的适配器实现本接口；核心库从不链接服务的 SDK。`completion` 在服务完成时所在的线程执行，且只执行一次。
 */
interface CYLRemoteConfigSource {
    /**
     * [EN] The service's identifier ("firebase"), which selects its mapper. [CN] 服务标识（"firebase"），用于选择其映射器。
     */
    val identifier: String

    /**
     * [EN] Fetches the values: the payload, or the failure (network, throttling, a service error). [CN] 拉取值：返回内容，或失败原因（网络、限流、服务错误）。
     */
    fun fetch(completion: (CYLRemoteConfigPayload?, Throwable?) -> Unit)
}

/**
 * [EN] Maps what a service delivered into the library's configuration dictionary. Throws `CYLConfigurationException` for a
 *      value that cannot be read, so the caller keeps its defaults. A mapper only converts: conditions, percentages and
 *      A/B tests were decided by the service, and are never evaluated again.
 * [CN] 把服务下发的内容映射为本库的配置字典。遇到无法读取的值时抛出 `CYLConfigurationException`，调用方因此保留默认值。映射器只做转换：条件、百分比与
 *      A/B 测试已由服务决定，不会再次计算。
 */
interface CYLRemoteConfigMapper {
    /**
     * [EN] The identifier of the service this mapper reads (`CYLRemoteConfigSource.identifier`). [CN] 本映射器读取的服务标识（`CYLRemoteConfigSource.identifier`）。
     */
    val sourceIdentifier: String

    @Throws(CYLTabBarConfiguration.CYLConfigurationException::class)
    fun configuration(payload: CYLRemoteConfigPayload): Map<String, Any?>
}

/**
 * [EN] The mappers by service identifier. "firebase" is registered; register another service's mapper to support it.
 * [CN] 按服务标识保存的映射器。已注册 "firebase"；注册其他服务的映射器即可支持该服务。
 */
object CYLRemoteConfigMappers {
    private val mappers = ConcurrentHashMap<String, CYLRemoteConfigMapper>()

    init {
        register(CYLFirebaseRemoteConfigMapper)
    }

    /**
     * [EN] Registers `mapper` for its `sourceIdentifier`, replacing an earlier one. [CN] 为 `mapper` 的 `sourceIdentifier` 注册，替换之前的映射器。
     */
    @JvmStatic
    fun register(mapper: CYLRemoteConfigMapper) {
        mappers[mapper.sourceIdentifier] = mapper
    }

    /**
     * [EN] Removes the mapper of `sourceIdentifier`; the Firebase one comes back with `register(CYLFirebaseRemoteConfigMapper)`.
     * [CN] 移除 `sourceIdentifier` 的映射器；Firebase 的可通过 `register(CYLFirebaseRemoteConfigMapper)` 恢复。
     */
    @JvmStatic
    fun unregister(sourceIdentifier: String) {
        mappers.remove(sourceIdentifier)
    }

    /**
     * [EN] The mapper of `sourceIdentifier`, or null. [CN] `sourceIdentifier` 的映射器，没有时为 null。
     */
    @JvmStatic
    fun mapper(sourceIdentifier: String): CYLRemoteConfigMapper? = mappers[sourceIdentifier]
}

/**
 * [EN] The mapper of Firebase Remote Config: flat parameters (one per top-level key), the `CYLTabBarConfiguration` whole-file
 *      parameter, JSON parameters for nested values, and the value type when the payload has one (a STRING stays a string,
 *      so a title "12" is not read as a number).
 * [CN] Firebase Remote Config 的映射器：扁平参数（每个顶层 key 一个）、`CYLTabBarConfiguration` 整个文件参数、嵌套值使用的 JSON 参数，以及内容带有值类型时按
 *      该类型处理（STRING 保持字符串，因此标题 "12" 不会被读成数字）。
 */
object CYLFirebaseRemoteConfigMapper : CYLRemoteConfigMapper {
    const val IDENTIFIER = "firebase"

    override val sourceIdentifier: String = IDENTIFIER

    @Throws(CYLTabBarConfiguration.CYLConfigurationException::class)
    override fun configuration(payload: CYLRemoteConfigPayload): Map<String, Any?> {
        val configuration = LinkedHashMap(
            try {
                CYLTabBarConfigurationParser.dictionaryWithRemoteConfigValues(payload.values)
            } catch (error: CYLTabBarConfigurationException) {
                throw CYLTabBarConfiguration.CYLConfigurationException(CYLTabBarConfigurationError.of(error.code), error.message ?: error.code.name)
            })
        for ((key, type) in payload.valueTypes) {
            val text = payload.values[key] as? String ?: continue
            if (type == CYLRemoteConfigValueType.STRING && key.startsWith(CYLRemoteConfigReader.PARAMETER_PREFIX) && key in configuration && text.isNotBlank()) {
                configuration[key] = text
            }
        }
        return configuration
    }
}

/**
 * [EN] The outcome of `CYLRemoteConfigLoader.load`: the configuration to build the tab bar from, whether the fetched values
 *      are in it, and why they are not (`error` is null when they are).
 * [CN] `CYLRemoteConfigLoader.load` 的结果：用于构建 TabBar 的配置、其中是否包含拉取到的值，以及没有包含的原因（包含时 `error` 为 null）。
 */
data class CYLRemoteConfigResult(
    val configuration: Map<String, Any?>,
    val isRemote: Boolean,
    val error: Throwable?,
)

/**
 * [EN] The fetch policy, over the interfaces: the defaults (the configuration file shipped in the app) are the answer at once
 *      when the fetch fails or the values are invalid; otherwise the mapped values replace the defaults key by key, as
 *      Remote Config's fetched values replace its in-app defaults. The result must have a tab, so a bad console edit never
 *      breaks the tab bar; a remote version number lower than the defaults' (`CYLTabBarControllerConfigurationVersion`) is refused as
 *      stale. `mapper` defaults to the one registered for the source (`CYLRemoteConfigMappers`).
 * [CN] 面向接口的拉取策略：拉取失败或值无效时，直接使用默认值（随 App 打包的配置文件）；否则映射后的值按 key 覆盖默认值，与 Remote Config 拉取的值覆盖应用内默认值
 *      的方式相同。结果必须有 Tab，因此控制台的错误编辑不会破坏 TabBar。`mapper` 默认使用为该服务注册的映射器（`CYLRemoteConfigMappers`）。
 */
class CYLRemoteConfigLoader(
    private val source: CYLRemoteConfigSource,
    private val mapper: CYLRemoteConfigMapper? = null,
) {
    /**
     * [EN] Fetches and merges. `completion` runs once, on the thread the source completes on. [CN] 拉取并合并。`completion` 只执行一次，在服务完成时所在的线程。
     */
    fun load(defaults: Map<String, Any?>, completion: (CYLRemoteConfigResult) -> Unit) {
        source.fetch { payload, failure ->
            completion(merged(defaults, payload, failure))
        }
    }

    private fun merged(defaults: Map<String, Any?>, payload: CYLRemoteConfigPayload?, failure: Throwable?): CYLRemoteConfigResult {
        fun keep(error: Throwable) = CYLRemoteConfigResult(defaults, false, error)
        if (payload == null) {
            return keep(failure ?: CYLTabBarConfiguration.CYLConfigurationException(CYLTabBarConfigurationError.Network, "The source returned no values."))
        }
        val chosen = mapper ?: CYLRemoteConfigMappers.mapper(payload.sourceIdentifier)
            ?: return keep(CYLTabBarConfiguration.CYLConfigurationException(CYLTabBarConfigurationError.UnknownFormat,
                "No mapper is registered for the remote configuration source \"${payload.sourceIdentifier}\"."))
        return try {
            val mapped = chosen.configuration(payload)
            // [EN] Version numbers only grow (Remote Config publishes a rollback under a new, higher number), so a lower number than
            //      the defaults' own is a stale or foreign template, never applied. No number on either side: the values apply.
            // [CN] 版本号只增不减（Remote Config 会以新的更大的编号发布回滚），因此低于默认值自身编号的是过期或不相干的模板，不会被应用。任何一方没有编号时，值照常应用。
            val remoteVersion = CYLTabBarConfiguration.versionNumber(mapped)
            val currentVersion = CYLTabBarConfiguration.versionNumber(defaults)
            if (remoteVersion != null && currentVersion != null && remoteVersion < currentVersion) {
                throw CYLTabBarConfiguration.CYLConfigurationException(CYLTabBarConfigurationError.NotEligible,
                    "The remote configuration is version $remoteVersion, older than the version $currentVersion in use.")
            }
            val result = LinkedHashMap(defaults)
            result.putAll(mapped)
            CYLTabBarConfiguration.requireTabs(result)
            CYLRemoteConfigResult(result, true, null)
        } catch (error: CYLTabBarConfiguration.CYLConfigurationException) {
            keep(error)
        }
    }
}
