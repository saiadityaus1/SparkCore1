package sparkSnowflake
import org.apache.spark.SparkConf
import org.apache.spark.SparkContext
import org.apache.spark.SparkContext
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._
import org.apache.spark.sql.hive._

object sparkSnowflake2 {

	def main(args:Array[String]):Unit={

			val conf=new SparkConf().setAppName("spark_integration").setMaster("local[*]")
					val sc=new SparkContext(conf)
					sc.setLogLevel("Error")
					val spark=SparkSession.builder().config(conf).enableHiveSupport().getOrCreate()
					import spark.implicits._



					val hc = new HiveContext(sc)
					import hc.implicits._


					println("=====================complex df========================")


			
					val df = spark.table("txn.txnrecords_ccash_hive")
					
					df.write.format("parquet").save("file:///home/cloudera/hivewrited")


			


	}
}