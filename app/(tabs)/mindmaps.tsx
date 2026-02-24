// mindmaps.tsx (upgrade)
import { Ionicons } from '@expo/vector-icons'
import AsyncStorage from '@react-native-async-storage/async-storage'
import * as FileSystem from 'expo-file-system'
import { LinearGradient } from 'expo-linear-gradient'
import React, { useCallback, useRef, useState, useEffect } from 'react'
import {
    Alert, Dimensions, Image, Platform,
    ScrollView,
    StyleSheet,
    Text,
    TextInput,
    TouchableOpacity,
    View
} from 'react-native'
import { SafeAreaView } from 'react-native-safe-area-context'
import { WebView } from 'react-native-webview'

// ---------- Gemini (JS client) ----------
import { GoogleGenerativeAI } from '@google/generative-ai'

// ---------- Firebase (optional but recommended) ----------

// ====== CONFIG ======
const { width } = Dimensions.get('window')

// Put your keys here (or from .env)
const GEMINI_API_KEY = 'AIzaSyC0VXu4sK_mh0CtAR9ppGn0afPHZRbZ6jg'
// const firebaseConfig = {
//   apiKey: "AIzaSyDnEfROOWpJq-Cpk83ciqTfU44DsE5cHg8",
//   authDomain: "studymate-bbd1c.firebaseapp.com",
//   projectId: "studymate-bbd1c",
//   storageBucket: "studymate-bbd1c.firebasestorage.app",
//   messagingSenderId: "239376838704",
//   appId: "1:239376838704:web:c5bb955701f613938d3df5",
//   measurementId: "G-TTFH3307K0"
// };

// Init Firebase (only once)
// const app = initializeApp(firebaseConfig)
// const db = getFirestore(app)
// const storage = getStorage(app)

// Example: current signed-in user id
const CURRENT_USER_ID = 'demo-user-1'

// ====== TYPES ======
interface MindMap {
    id: string
    title: string
    topic: string
    createdAt: Date
    nodes: number
    category: string
    thumbnail?: string
    folderId?: string
    fileId?: string       // Firestore file id for the tldraw snapshot
}

export default function MindmapsScreen() {
    const [mindmaps, setMindmaps] = useState<MindMap[]>([])
    const [isLoading, setIsLoading] = useState(true)
    const [topicInput, setTopicInput] = useState('')
    const [isGenerating, setIsGenerating] = useState(false)
    const [selectedMindmap, setSelectedMindmap] = useState<MindMap | null>(null)
    const [showWebView, setShowWebView] = useState(false)
    const [selectedCategory, setSelectedCategory] = useState('All')
    const categories = ['All', 'Science', 'Mathematics', 'History', 'Language', 'Arts', 'AI Generated']

    const filteredMindmaps = mindmaps.filter(m =>
        selectedCategory === 'All' || m.category === selectedCategory
    )

    // ============ PERSISTENT STORAGE ============
    const MINDMAPS_STORAGE_KEY = `mindmaps:${CURRENT_USER_ID}`

    // Load mindmaps from storage on mount
    useEffect(() => {
        loadMindmaps()
    }, [])

    const loadMindmaps = async () => {
        try {
            const stored = await AsyncStorage.getItem(MINDMAPS_STORAGE_KEY)
            if (stored) {
                const parsed = JSON.parse(stored)
                // Convert date strings back to Date objects
                const withDates = parsed.map((m: any) => ({
                    ...m,
                    createdAt: new Date(m.createdAt)
                }))
                setMindmaps(withDates)
            }
        } catch (error) {
            console.error('Failed to load mindmaps:', error)
        } finally {
            setIsLoading(false)
        }
    }

    const saveMindmaps = async (maps: MindMap[]) => {
        try {
            await AsyncStorage.setItem(MINDMAPS_STORAGE_KEY, JSON.stringify(maps))
        } catch (error) {
            console.error('Failed to save mindmaps:', error)
        }
    }

    const deleteMindmap = async (mindmap: MindMap) => {
        Alert.alert(
            'Delete Mindmap',
            `Are you sure you want to delete "${mindmap.title}"?`,
            [
                { text: 'Cancel', style: 'cancel' },
                {
                    text: 'Delete',
                    style: 'destructive',
                    onPress: async () => {
                        try {
                            // Remove from state
                            const updatedMaps = mindmaps.filter(m => m.id !== mindmap.id)
                            setMindmaps(updatedMaps)
                            
                            // Remove from storage
                            await saveMindmaps(updatedMaps)
                            
                            // Remove mindmap data
                            const cacheKey = cacheKeyFor(mindmap)
                            await AsyncStorage.removeItem(cacheKey)
                            
                            Alert.alert('Success', 'Mindmap deleted successfully')
                        } catch (error) {
                            console.error('Failed to delete mindmap:', error)
                            Alert.alert('Error', 'Failed to delete mindmap')
                        }
                    }
                }
            ]
        )
    }

    // ============ GEMINI ============
    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY)
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' })

    async function generateWithGemini(topic: string) {
        const prompt = `Create a detailed hierarchical mindmap for the topic: "${topic}"

Return ONLY a JSON object with this exact structure:
{
  "name": "${topic}",
  "explanation": "Brief overview of the main topic in 1-2 sentences",
  "children": [
    {
      "name": "Main Branch 1",
      "explanation": "Clear explanation of why this branch is important and what it covers",
      "children": [
        {
          "name": "Sub-topic 1",
          "explanation": "Specific explanation of this concept and its relevance"
        },
        {
          "name": "Sub-topic 2",
          "explanation": "Detailed description of this aspect and how it relates to the main branch"
        }
      ]
    },
    {
      "name": "Main Branch 2",
      "explanation": "Clear explanation of this branch's significance and scope",
      "children": [
        {
          "name": "Sub-topic A",
          "explanation": "Meaningful explanation of this concept with practical context"
        },
        {
          "name": "Sub-topic B",
          "explanation": "Comprehensive description of this element and its applications"
        }
      ]
    }
  ]
}

Rules:
- Include 3-5 main branches
- Each main branch should have 2-4 sub-topics
- Keep node names concise (1-4 words)
- Provide meaningful explanations for ALL nodes (root, branches, and sub-topics)
- Explanations should be educational, clear, and 1-3 sentences
- Only expand or explain terms when necessary for understanding
- Make explanations specific to the context and practical
- Return valid JSON only, no markdown formatting or other text`
        
        const res = await model.generateContent(prompt)
        const text = res.response.text()
        
        // Try to parse JSON from Gemini; handle fenced code or extra text
        const json = tryParseFirstJSON(text)
        
        if (!json || !json.name) {
            // Fallback structure if Gemini fails
            console.warn('Gemini returned invalid JSON, using fallback')
            return createFallbackMindmap(topic)
        }
        
        return json
    }

    function tryParseFirstJSON(s: string) {
        // naive extractor; improve if needed
        const start = s.indexOf('{')
        const end = s.lastIndexOf('}')
        if (start === -1 || end === -1 || end <= start) return null
        try { return JSON.parse(s.slice(start, end + 1)) } catch { return null }
    }

    function createFallbackMindmap(topic: string) {
        // Create a basic mindmap structure when Gemini fails
        return {
            name: topic,
            explanation: `A comprehensive overview of ${topic}, exploring its fundamental aspects, practical applications, and connections to related concepts.`,
            children: [
                {
                    name: "Key Concepts",
                    explanation: `Essential foundational knowledge and terminology needed to understand ${topic}.`,
                    children: [
                        { 
                            name: "Definition", 
                            explanation: `The fundamental meaning and scope of ${topic}, including its core characteristics.`
                        },
                        { 
                            name: "Components", 
                            explanation: `The main parts, elements, or building blocks that make up ${topic}.`
                        },
                        { 
                            name: "Examples", 
                            explanation: `Real-world instances and illustrations that demonstrate ${topic} in practice.`
                        }
                    ]
                },
                {
                    name: "Applications",
                    explanation: `How ${topic} is used and applied in various contexts and scenarios.`,
                    children: [
                        { 
                            name: "Practical Uses", 
                            explanation: `Direct, hands-on applications where ${topic} provides tangible benefits and solutions.`
                        },
                        { 
                            name: "Real World", 
                            explanation: `Actual implementations and occurrences of ${topic} in everyday life and industry.`
                        },
                        { 
                            name: "Benefits", 
                            explanation: `The advantages, improvements, and positive outcomes that result from using ${topic}.`
                        }
                    ]
                },
                {
                    name: "Related Topics",
                    explanation: `Connected subjects and areas of study that complement and expand understanding of ${topic}.`,
                    children: [
                        { 
                            name: "Similar Concepts", 
                            explanation: `Topics that share characteristics or principles with ${topic}, offering comparative insights.`
                        },
                        { 
                            name: "Connected Ideas", 
                            explanation: `Broader themes and disciplines that intersect with or build upon ${topic}.`
                        }
                    ]
                }
            ]
        }
    }
    // ============ GoJS mindmap helpers ============
    // empty GoJS model structure
    const emptySnapshot = { nodeDataArray: [], linkDataArray: [] }

    // map hierarchical tree -> GoJS model with nodes and links
    function treeToGoJSModel(tree: any) {
        const nodeDataArray: any[] = []
        const linkDataArray: any[] = []
        let keyCounter = 1

        // recursive walk to create nodes and links
        function walk(node: any, parentKey?: number) {
            const key = keyCounter++
            nodeDataArray.push({
                key: key,
                text: node.name || 'Node',
                explanation: node.explanation || '',
                category: parentKey ? 'child' : 'root'
            })

            if (parentKey) {
                linkDataArray.push({
                    from: parentKey,
                    to: key
                })
            }

            const children = Array.isArray(node.children) ? node.children : []
            children.forEach((child: any) => walk(child, key))
        }

        walk(tree)
        return { nodeDataArray, linkDataArray }
    }

    // ============ Create & Generate ============
    // const createFileInCloud = async (folderId: string, title: string, snapshot: any) => {
    //     const ref = await addDoc(collection(db, `users/${CURRENT_USER_ID}/files`), {
    //         folderId, ownerId: CURRENT_USER_ID, title, type: 'tldraw',
    //         snapshot, updatedAt: serverTimestamp(), clientUpdatedAt: Date.now()
    //     })
    //     return ref.id
    // }

    const generateMindmap = async () => {
        if (!topicInput.trim()) {
            Alert.alert('Error', 'Please enter a topic');
            return;
        }

        try {
            setIsGenerating(true);

            // 1) Get mindmap tree from Gemini
            const tree = await generateWithGemini(topicInput.trim());

            // 2) Convert to GoJS model
            const snap = treeToGoJSModel(tree);

            // 3) Create card locally
            const newMindmap: MindMap = {
                id: Date.now().toString(),
                title: `${topicInput.trim()} Overview`,
                topic: topicInput.trim(),
                createdAt: new Date(),
                nodes: countTreeNodes(tree),
                category: 'AI Generated',
            };
            const updatedMindmaps = [newMindmap, ...mindmaps];
            setMindmaps(updatedMindmaps);

            // 4) Save mindmap data and list
            const cacheKey = cacheKeyFor(newMindmap);
            await AsyncStorage.setItem(
                cacheKey,
                JSON.stringify({ snapshot: snap, updatedAt: Date.now() })
            );
            await saveMindmaps(updatedMindmaps);

            setTopicInput('');
            Alert.alert('Success', `Generated mindmap for ${newMindmap.topic}`);
        } catch (e: any) {
            console.error(e);
            Alert.alert('Generation failed', e?.message ?? 'Unknown error');
        } finally {
            setIsGenerating(false);
        }
    };


    function countTreeNodes(node: any): number {
        const kids = Array.isArray(node.children) ? node.children : []
        return 1 + kids.reduce((a: number, c: any) => a + countTreeNodes(c), 0)
    }

    // async function ensureDefaultFolder(name: string) {
    //     const q = query(collection(db, `users/${CURRENT_USER_ID}/folders`), where('name', '==', name))
    //     const res = await getDocs(q)
    //     if (!res.empty) return res.docs[0].id
    //     const ref = await addDoc(collection(db, `users/${CURRENT_USER_ID}/folders`), {
    //         name, createdAt: serverTimestamp(), updatedAt: serverTimestamp(), parentId: null
    //     })
    //     return ref.id
    // }

    // ============ Editor (WebView) ============
    const webRef = useRef<WebView>(null)
    const [editorFile, setEditorFile] = useState<{ map: MindMap; snapshot: any } | null>(null)

    const openMindmap = async (map: MindMap) => {
        const cacheKey = cacheKeyFor(map);
        const cached = await AsyncStorage.getItem(cacheKey);
        const snapshot = cached ? JSON.parse(cached).snapshot : emptySnapshot;

        setEditorFile({ map, snapshot });
        setSelectedMindmap(map);
        setShowWebView(true);

        console.log('Opening mindmap with snapshot:', snapshot);
        setTimeout(() => postToWeb('LOAD_DOC', snapshot), 50);
    };


    // async function refreshFromCloud(map: MindMap) {
    //     const snap = await getDoc(doc(db, `users/${CURRENT_USER_ID}/files/${map.fileId}`))
    //     if (!snap.exists()) return
    //     const cloud = snap.data() as any
    //     const cacheKey = cacheKeyFor(map)
    //     const local = await AsyncStorage.getItem(cacheKey).then(s => s ? JSON.parse(s) : null)
    //     // simple last-write-wins
    //     const cloudTs = cloud.clientUpdatedAt ?? 0
    //     const localTs = local?.updatedAt ?? 0
    //     if (cloudTs > localTs) {
    //         await AsyncStorage.setItem(cacheKey, JSON.stringify({ snapshot: cloud.snapshot, updatedAt: cloudTs }))
    //         postToWeb('LOAD_DOC', cloud.snapshot)
    //     }
    // }

    function postToWeb(type: string, payload?: any) {
        console.log('Sending to web:', { type, payload });
        webRef.current?.postMessage(JSON.stringify({ type, payload }))
    }

    const onWebMessage = useCallback(async (e: any) => {
        try {
            const msg = JSON.parse(e.nativeEvent.data);
            console.log('Message from WebView:', msg);
            
            // When WebView is ready, send the mindmap data
            if (msg.type === 'READY') {
                console.log('WebView ready, sending data in 100ms');
                setTimeout(() => {
                    if (selectedMindmap) {
                        const cacheKey = cacheKeyFor(selectedMindmap);
                        AsyncStorage.getItem(cacheKey).then(cached => {
                            const snapshot = cached ? JSON.parse(cached).snapshot : emptySnapshot;
                            console.log('Sending stored snapshot:', snapshot);
                            postToWeb('LOAD_DOC', snapshot);
                        });
                    }
                }, 100);
            }
            
            if (msg.type === 'DOC_CHANGED' && selectedMindmap) {
                const { snapshot, updatedAt } = msg.payload;
                const cacheKey = cacheKeyFor(selectedMindmap);
                await AsyncStorage.setItem(cacheKey, JSON.stringify({ snapshot, updatedAt }));
            }
            if (msg.type === 'EXPORT_PNG_RESULT' || msg.type === 'EXPORT_SVG_RESULT') {
                const { base64, mime } = msg.payload;
                const ext = mime === 'image/svg+xml' ? 'svg' : 'png';
                const fileUri = FileSystem.cacheDirectory + `mindmap-export.${ext}`;
                await FileSystem.writeAsStringAsync(fileUri, base64, {
                    encoding: FileSystem.EncodingType.Base64,
                });
                Alert.alert('Exported', `Saved to: ${fileUri}`);
            }
        } catch { }
    }, [selectedMindmap]);


    // debounced cloud save
    // let saveTimer: any
    // function scheduleCloudSave(map: MindMap, snapshot: any, ts: number) {
    //     if (saveTimer) clearTimeout(saveTimer)
    //     saveTimer = setTimeout(() => saveToCloud(map, snapshot, ts), 700)
    // }

    // async function saveToCloud(map: MindMap, snapshot: any, ts: number) {
    //     if (!map.fileId) {
    //         // create it
    //         const folderId = map.folderId || await ensureDefaultFolder('AI Mindmaps')
    //         const fileId = await createFileInCloud(folderId, map.title, snapshot)
    //         setMindmaps(prev => prev.map(m => m.id === map.id ? ({ ...m, fileId, folderId }) : m))
    //         return
    //     }
    //     await setDoc(doc(db, `users/${CURRENT_USER_ID}/files/${map.fileId}`), {
    //         snapshot, updatedAt: serverTimestamp(), clientUpdatedAt: ts
    //     }, { merge: true })
    // }

    const exportPNG = () => postToWeb('EXPORT_PNG')
    const exportSVG = () => postToWeb('EXPORT_SVG')

    function cacheKeyFor(m: MindMap) {
        return `tldraw:${CURRENT_USER_ID}:${m.fileId || m.id}`
    }

    // ======== UI (your existing layout kept, with actions wired) ========

    if (showWebView && selectedMindmap) {
        return (
            <SafeAreaView style={styles.container}>
                <View style={styles.webViewHeader}>
                    <TouchableOpacity onPress={() => { setShowWebView(false); setSelectedMindmap(null) }}>
                        <Ionicons name="arrow-back" size={24} color="#667eea" />
                    </TouchableOpacity>
                    <Text style={styles.webViewTitle}>{selectedMindmap.title}</Text>
                    <View style={{ flexDirection: 'row', gap: 16 }}>
                        <TouchableOpacity onPress={exportPNG}><Ionicons name="image-outline" size={22} color="#667eea" /></TouchableOpacity>
                        <TouchableOpacity onPress={exportSVG}><Ionicons name="code-slash-outline" size={22} color="#667eea" /></TouchableOpacity>
                    </View>
                </View>

                <WebView
                    ref={webRef}
                    originWhitelist={['*']}
                    source={
                        Platform.select({
                            ios: require('../../assets/mindmap_editor.html'),
                            android: { uri: 'file:///android_asset/mindmap_editor.html' }
                        }) as any
                    }
                    allowingReadAccessToURL={'file:///android_asset/'}
                    allowFileAccess
                    allowUniversalAccessFromFileURLs
                    javaScriptEnabled
                    domStorageEnabled
                    onMessage={onWebMessage}
                    style={styles.webView}
                />
            </SafeAreaView>
        )
    }

    return (
        <SafeAreaView style={styles.container}>
            <ScrollView style={styles.scrollView} showsVerticalScrollIndicator={false}>
                {/* Header */}
                <View style={styles.header}>
                    <Text style={styles.headerTitle}>AI Mindmaps</Text>
                    <TouchableOpacity style={styles.statsButton}>
                        <Ionicons name="analytics-outline" size={24} color="#667eea" />
                    </TouchableOpacity>
                </View>

                {/* Stats */}
                <View style={styles.statsSection}>
                    <LinearGradient colors={['#667eea', '#764ba2']} style={styles.statsCard}>
                        <View style={styles.statItem}><Text style={styles.statNumber}>{mindmaps.length}</Text><Text style={styles.statLabel}>Total Maps</Text></View>
                        <View style={styles.statItem}><Text style={styles.statNumber}>{categories.length - 1}</Text><Text style={styles.statLabel}>Categories</Text></View>
                        <View style={styles.statItem}><Text style={styles.statNumber}>{mindmaps.reduce((s, m) => s + m.nodes, 0)}</Text><Text style={styles.statLabel}>Total Nodes</Text></View>
                    </LinearGradient>
                </View>

                {/* Generate */}
                <View style={styles.generationSection}>
                    <Text style={styles.sectionTitle}>Generate New Mindmap</Text>
                    <View style={styles.generationCard}>
                        <Image source={require('../../assets/images/logo_ai_generated_mindmaps.png')} style={styles.aiIcon} />
                        <Text style={styles.generationDescription}>
                            Enter any topic and AI will create a comprehensive mindmap you can edit and save.
                        </Text>
                        <TextInput
                            style={styles.topicInput}
                            placeholder="Enter topic (e.g., Photosynthesis, Renaissance Art, Machine Learning)"
                            value={topicInput}
                            onChangeText={setTopicInput}
                        />
                        <TouchableOpacity
                            style={[styles.generateButton, isGenerating && styles.generateButtonDisabled]}
                            onPress={generateMindmap}
                            disabled={isGenerating}
                        >
                            <Text style={styles.generateButtonText}>{isGenerating ? 'Generating…' : 'Generate Mindmap'}</Text>
                            <Ionicons name="git-network-outline" size={20} color="#fff" />
                        </TouchableOpacity>
                    </View>
                </View>

                {/* Categories */}
                <View style={styles.categorySection}>
                    <Text style={styles.sectionTitle}>Categories</Text>
                    <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                        <View style={styles.categoryContainer}>
                            {categories.map((c) => (
                                <TouchableOpacity key={c}
                                    style={[styles.categoryChip, selectedCategory === c && styles.categoryChipActive]}
                                    onPress={() => setSelectedCategory(c)}
                                >
                                    <Text style={[styles.categoryChipText, selectedCategory === c && styles.categoryChipTextActive]}>{c}</Text>
                                </TouchableOpacity>
                            ))}
                        </View>
                    </ScrollView>
                </View>

                {/* Grid */}
                <View style={styles.mindmapsSection}>
                    <View style={styles.mindmapsHeader}>
                        <Text style={styles.sectionTitle}>Your Mindmaps</Text>
                        <TouchableOpacity style={styles.sortButton}>
                            <Ionicons name="filter-outline" size={20} color="#667eea" />
                            <Text style={styles.sortText}>Sort</Text>
                        </TouchableOpacity>
                    </View>

                    {filteredMindmaps.length === 0 ? (
                        <View style={styles.emptyState}>
                            <Image source={require('../../assets/images/logo_for_mindmap.png')} style={styles.emptyStateIcon} />
                            <Text style={styles.emptyStateText}>No mindmaps in this category</Text>
                            <Text style={styles.emptyStateSubtext}>Generate your first mindmap to get started!</Text>
                        </View>
                    ) : (
                        <View style={styles.mindmapsGrid}>
                            {filteredMindmaps.map((m) => (
                                <TouchableOpacity key={m.id} style={styles.mindmapCard} onPress={() => openMindmap(m)}>
                                    <LinearGradient colors={['#667eea', '#764ba2']} style={styles.mindmapThumbnail}>
                                        <Ionicons name="git-network-outline" size={32} color="#fff" />
                                    </LinearGradient>
                                    <View style={styles.mindmapContent}>
                                        <View style={styles.mindmapHeader}>
                                            <Text style={styles.mindmapTitle} numberOfLines={2}>{m.title}</Text>
                                            <View style={styles.categoryBadge}><Text style={styles.categoryBadgeText}>{m.category}</Text></View>
                                        </View>
                                        <Text style={styles.mindmapTopic} numberOfLines={1}>{m.topic}</Text>
                                        <View style={styles.mindmapFooter}>
                                            <View style={styles.mindmapStats}><Ionicons name="ellipse" size={12} color="#667eea" /><Text style={styles.nodesCount}>{m.nodes} nodes</Text></View>
                                            <Text style={styles.mindmapDate}>{m.createdAt.toLocaleDateString()}</Text>
                                        </View>
                                    </View>
                                    <TouchableOpacity style={styles.mindmapAction} onPress={() => deleteMindmap(m)}><Ionicons name="trash-outline" size={16} color="#e74c3c" /></TouchableOpacity>
                                </TouchableOpacity>
                            ))}
                        </View>
                    )}
                </View>
            </ScrollView>
        </SafeAreaView>
    )
}

// (keep your existing StyleSheet exactly as in your file)
const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#F8F9FA',
    },
    scrollView: {
        flex: 1,
    },
    header: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingHorizontal: 20,
        paddingVertical: 16,
    },
    headerTitle: {
        fontSize: 28,
        fontWeight: 'bold',
        color: '#2C3E50',
    },
    statsButton: {
        padding: 8,
    },
    statsSection: {
        paddingHorizontal: 20,
        marginBottom: 24,
    },
    statsCard: {
        flexDirection: 'row',
        justifyContent: 'space-around',
        padding: 20,
        borderRadius: 12,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
        elevation: 4,
    },
    statItem: {
        alignItems: 'center',
    },
    statNumber: {
        fontSize: 24,
        fontWeight: 'bold',
        color: '#FFFFFF',
        marginBottom: 4,
    },
    statLabel: {
        fontSize: 12,
        color: '#FFFFFF',
        opacity: 0.8,
    },
    generationSection: {
        paddingHorizontal: 20,
        marginBottom: 24,
    },
    sectionTitle: {
        fontSize: 20,
        fontWeight: '600',
        color: '#2C3E50',
        marginBottom: 16,
    },
    generationCard: {
        backgroundColor: '#FFFFFF',
        borderRadius: 12,
        padding: 20,
        alignItems: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
        elevation: 4,
    },
    aiIcon: {
        width: 64,
        height: 64,
        marginBottom: 16,
    },
    generationDescription: {
        fontSize: 14,
        color: '#7F8C8D',
        textAlign: 'center',
        marginBottom: 16,
        lineHeight: 20,
    },
    topicInput: {
        width: '100%',
        borderWidth: 1,
        borderColor: '#E1E8ED',
        borderRadius: 8,
        padding: 12,
        fontSize: 16,
        marginBottom: 16,
        textAlign: 'center',
    },
    generateButton: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: '#667eea',
        paddingHorizontal: 20,
        paddingVertical: 12,
        borderRadius: 8,
    },
    generateButtonDisabled: {
        opacity: 0.6,
    },
    generateButtonText: {
        color: '#FFFFFF',
        fontSize: 16,
        fontWeight: '600',
        marginRight: 8,
    },
    categorySection: {
        marginBottom: 24,
    },
    categoryContainer: {
        flexDirection: 'row',
        paddingHorizontal: 20,
    },
    categoryChip: {
        paddingHorizontal: 16,
        paddingVertical: 8,
        borderRadius: 20,
        backgroundColor: '#FFFFFF',
        marginRight: 8,
        borderWidth: 1,
        borderColor: '#E1E8ED',
    },
    categoryChipActive: {
        backgroundColor: '#667eea',
        borderColor: '#667eea',
    },
    categoryChipText: {
        fontSize: 14,
        color: '#2C3E50',
    },
    categoryChipTextActive: {
        color: '#FFFFFF',
        fontWeight: '500',
    },
    mindmapsSection: {
        paddingHorizontal: 20,
        marginBottom: 24,
    },
    mindmapsHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 16,
    },
    sortButton: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: '#F0F4FF',
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 6,
    },
    sortText: {
        color: '#667eea',
        fontSize: 14,
        fontWeight: '500',
        marginLeft: 4,
    },
    emptyState: {
        alignItems: 'center',
        paddingVertical: 40,
    },
    emptyStateIcon: {
        width: 64,
        height: 64,
        marginBottom: 16,
    },
    emptyStateText: {
        fontSize: 18,
        color: '#7F8C8D',
        marginBottom: 8,
    },
    emptyStateSubtext: {
        fontSize: 14,
        color: '#BDC3C7',
    },
    mindmapsGrid: {
        gap: 12,
    },
    mindmapCard: {
        flexDirection: 'row',
        backgroundColor: '#FFFFFF',
        borderRadius: 12,
        padding: 12,
        marginBottom: 12,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
        elevation: 3,
    },
    mindmapThumbnail: {
        width: 60,
        height: 60,
        borderRadius: 8,
        justifyContent: 'center',
        alignItems: 'center',
        marginRight: 12,
    },
    mindmapContent: {
        flex: 1,
    },
    mindmapHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'flex-start',
        marginBottom: 4,
    },
    mindmapTitle: {
        fontSize: 16,
        fontWeight: '600',
        color: '#2C3E50',
        flex: 1,
        marginRight: 8,
    },
    categoryBadge: {
        backgroundColor: '#F0F4FF',
        paddingHorizontal: 8,
        paddingVertical: 2,
        borderRadius: 4,
    },
    categoryBadgeText: {
        fontSize: 10,
        color: '#667eea',
        fontWeight: '500',
    },
    mindmapTopic: {
        fontSize: 14,
        color: '#7F8C8D',
        marginBottom: 8,
    },
    mindmapFooter: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    mindmapStats: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    nodesCount: {
        fontSize: 12,
        color: '#667eea',
        marginLeft: 4,
        fontWeight: '500',
    },
    mindmapDate: {
        fontSize: 12,
        color: '#BDC3C7',
    },
    mindmapAction: {
        padding: 8,
        justifyContent: 'center',
    },
    quickActionsSection: {
        paddingHorizontal: 20,
        marginBottom: 24,
    },
    quickActions: {
        flexDirection: 'row',
        justifyContent: 'space-between',
    },
    quickActionCard: {
        flex: 1,
        marginHorizontal: 4,
    },
    quickActionGradient: {
        padding: 16,
        borderRadius: 12,
        alignItems: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 4,
        elevation: 3,
    },
    quickActionText: {
        color: '#FFFFFF',
        fontSize: 12,
        fontWeight: '600',
        marginTop: 8,
        textAlign: 'center',
    },

    // WebView Styles
    webViewHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingHorizontal: 20,
        paddingVertical: 16,
        borderBottomWidth: 1,
        borderBottomColor: '#E1E8ED',
        backgroundColor: '#FFFFFF',
    },
    webViewTitle: {
        fontSize: 18,
        fontWeight: '600',
        color: '#2C3E50',
    },
    webView: {
        flex: 1,
    },
});
