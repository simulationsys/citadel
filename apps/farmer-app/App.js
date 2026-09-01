import { SafeAreaView, ScrollView, StyleSheet, Text, View } from 'react-native';

const alerts = [{ title: 'Irrigate now', detail: 'Zone A has low soil moisture. Run irrigation for 15 minutes.' }, { title: 'Leaf scan', detail: 'Take a clear leaf photo to check disease and pests.' }];
export default function App() { return <SafeAreaView style={styles.page}><ScrollView contentContainerStyle={styles.content}><Text style={styles.title}>Citadel Farm</Text><Text style={styles.sub}>Offline field assistant</Text>{alerts.map((alert) => <View key={alert.title} style={styles.card}><Text style={styles.cardTitle}>{alert.title}</Text><Text>{alert.detail}</Text></View>)}</ScrollView></SafeAreaView>; }
const styles = StyleSheet.create({ page:{flex:1,backgroundColor:'#f4f7f1'},content:{padding:24,gap:14},title:{fontSize:30,fontWeight:'700',color:'#183d23'},sub:{color:'#5d6d60'},card:{backgroundColor:'#fff',padding:18,borderRadius:12,gap:8},cardTitle:{fontWeight:'700',fontSize:18} });
